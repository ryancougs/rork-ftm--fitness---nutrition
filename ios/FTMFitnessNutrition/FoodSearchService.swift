//
//  FoodSearchService.swift
//  FTMFitnessNutrition
//

import Foundation

/// Outcome of a remote food search.
struct FoodSearchOutcome {
    var results: [FoodItem]
    var failedSources: [String]   // friendly names, shown as a soft notice
}

/// Searches Open Food Facts (no key) and USDA FoodData Central (key required)
/// and merges results. Every failure degrades gracefully: the caller always
/// keeps local results, and failed sources are reported by name.
struct FoodSearchService {
    static let shared = FoodSearchService()

    /// USDA FoodData Central key, set as a build variable. Empty → USDA quietly off.
    /// Dictionary lookup keeps this compiling even before the key lands in the generated Config.
    private var usdaKey: String { Config.allValues["EXPO_PUBLIC_USDA_API_KEY"] ?? "" }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 12
        config.httpAdditionalHeaders = ["User-Agent": "TransFit/1.0 (support@transfit.app)"]
        return URLSession(configuration: config)
    }()

    // MARK: - Search

    func search(query: String) async -> FoodSearchOutcome {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            return FoodSearchOutcome(results: [], failedSources: [])
        }

        async let offResult = searchOpenFoodFacts(trimmed)
        async let usdaResult = searchUSDA(trimmed)
        let (off, usda) = await (offResult, usdaResult)

        var failed: [String] = []
        var remote: [FoodItem] = []
        if case .success(let items) = off {
            remote += items
        } else {
            failed.append("Open Food Facts")
        }
        if case .success(let items) = usda {
            remote += items
        } else if !usdaKey.isEmpty {
            failed.append("USDA")
        }

        return FoodSearchOutcome(results: deduped(remote), failedSources: failed)
    }

    // MARK: - Barcode

    /// Looks a product up by barcode on Open Food Facts. Nil when unknown.
    func lookupBarcode(_ code: String) async -> FoodItem? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json?fields=code,product_name,brands,serving_quantity,serving_unit,nutriments") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try JSONDecoder().decode(OFFBarcodeResponse.self, from: data)
            guard decoded.status == 1, let product = decoded.product else { return nil }
            return food(from: product)
        } catch {
            print("Barcode lookup failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Open Food Facts

    private enum SourceResult {
        case success([FoodItem])
        case failure
    }

    private func searchOpenFoodFacts(_ query: String) async -> SourceResult {
        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "fields", value: "code,product_name,brands,serving_quantity,serving_unit,nutriments"),
        ]
        do {
            let (data, _) = try await session.data(from: components.url!)
            let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
            let items = (decoded.products ?? [])
                .compactMap { food(from: $0) }
            return .success(Array(items.prefix(15)))
        } catch {
            print("Open Food Facts search failed: \(error.localizedDescription)")
            return .failure
        }
    }

    // MARK: - USDA FoodData Central

    private func searchUSDA(_ query: String) async -> SourceResult {
        guard !usdaKey.isEmpty else { return .success([]) }
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: usdaKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "15"),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy,Survey (FNDDS)"),
        ]
        do {
            let (data, _) = try await session.data(from: components.url!)
            let decoded = try JSONDecoder().decode(USDAResponse.self, from: data)
            let items = (decoded.foods ?? []).compactMap { food(from: $0) }
            return .success(items)
        } catch {
            print("USDA search failed: \(error.localizedDescription)")
            return .failure
        }
    }

    // MARK: - Mapping

    private func food(from p: OFFProduct) -> FoodItem? {
        guard let name = p.productName?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
              let kcal = p.nutriments?.kcal100, kcal > 0 else { return nil }
        let brand = p.brands?
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespaces)
        let grams = p.servingQuantity?.value.flatMap { $0 > 0 ? $0 : nil }
        let factor = grams.map { $0 / 100 } ?? 1
        return FoodItem(
            name: name,
            serving: grams != nil ? "1 serving (\(Int(grams!)) g)" : "100 g",
            calories: Int((kcal * factor).rounded()),
            protein: Int(((p.nutriments?.protein100 ?? 0) * factor).rounded()),
            carbs: Int(((p.nutriments?.carbs100 ?? 0) * factor).rounded()),
            fat: Int(((p.nutriments?.fat100 ?? 0) * factor).rounded()),
            brand: (brand?.isEmpty ?? true) ? nil : brand,
            barcode: p.code,
            source: .openFoodFacts,
            kcalPer100g: kcal,
            proteinPer100g: p.nutriments?.protein100,
            carbsPer100g: p.nutriments?.carbs100,
            fatPer100g: p.nutriments?.fat100,
            servingGrams: grams
        )
    }

    private func food(from f: USDAFood) -> FoodItem? {
        guard let name = f.description?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { return nil }
        var kcal: Double?
        var protein: Double?
        var carbs: Double?
        var fat: Double?
        for n in f.foodNutrients ?? [] {
            let lowered = (n.nutrientName ?? "").lowercased()
            let value = n.value ?? 0
            if lowered == "energy", (n.unitName ?? "").lowercased().contains("kcal") {
                kcal = value
            } else if lowered.hasPrefix("protein") {
                protein = value
            } else if lowered.hasPrefix("carbohydrate") {
                carbs = value
            } else if lowered.contains("lipid") {
                fat = value
            }
        }
        guard let kcal, kcal > 0 else { return nil }
        return FoodItem(
            name: name,
            serving: "100 g",
            calories: Int(kcal.rounded()),
            protein: Int((protein ?? 0).rounded()),
            carbs: Int((carbs ?? 0).rounded()),
            fat: Int((fat ?? 0).rounded()),
            source: .usda,
            kcalPer100g: kcal,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat
        )
    }

    /// Removes duplicates by stable key (name + brand + barcode).
    private func deduped(_ items: [FoodItem]) -> [FoodItem] {
        var seen = Set<String>()
        var unique: [FoodItem] = []
        for item in items where seen.insert(item.stableKey).inserted {
            unique.append(item)
        }
        return unique
    }
}

// MARK: - Open Food Facts DTOs

private struct OFFResponse: Decodable {
    let products: [OFFProduct]?
}

private struct OFFBarcodeResponse: Decodable {
    let status: Int?
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingQuantity: FlexDouble?
    let servingUnit: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingQuantity = "serving_quantity"
        case servingUnit = "serving_unit"
        case nutriments
    }
}

/// OFF returns numbers sometimes as JSON numbers, sometimes as strings.
private struct FlexDouble: Decodable {
    let value: Double?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) {
            value = d
        } else if let s = try? c.decode(String.self) {
            value = Double(s.replacingOccurrences(of: ",", with: "."))
        } else {
            value = nil
        }
    }
}

private struct OFFNutriments: Decodable {
    let kcal100: Double?
    let protein100: Double?
    let carbs100: Double?
    let fat100: Double?

    enum CodingKeys: String, CodingKey {
        case kcal100 = "energy-kcal_100g"
        case protein100 = "proteins_100g"
        case carbs100 = "carbohydrates_100g"
        case fat100 = "fat_100g"
    }
}

// MARK: - USDA DTOs

private struct USDAResponse: Decodable {
    let foods: [USDAFood]?
}

private struct USDAFood: Decodable {
    let fdcId: Int?
    let description: String?
    let foodNutrients: [USDANutrient]?
}

private struct USDANutrient: Decodable {
    let nutrientName: String?
    let unitName: String?
    let value: Double?
}
