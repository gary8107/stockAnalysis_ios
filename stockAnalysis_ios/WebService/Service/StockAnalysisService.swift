//
//  StockAnalysisService.swift
//
//  範例 Service：示範如何定義一支 API。
//  其他專案要新增 API 時，照這個樣板複製即可。
//

import Moya
import Alamofire

enum StockAnalysisService {

    /// 取得個股分析資料。
    final class GetStockAnalysis: DecodableTargetType, DynamicCacheable {

        // MARK: API 定義
        typealias Response = StockAnalysisInfo

        let baseURL = URL(string: "https://gary8107.github.io")!
        let path = "/stockAnalysis/api/notes.json"
        let method: Moya.Method = .get

        /// 是否走快取：此資料更新頻繁，預設每次重新抓。
        let cached = false

        var task: Task {
            return .requestQueryEncodable(query)
        }

        /// stub 模式（STUB=true）時回傳的本地假資料。
        var sampleData: Data {
            (try? MockData.fromJsonFile(fileName: "stockAnalysisInfo.json")) ?? Data()
        }

        // MARK: Query
        struct Query: Encodable {
            let date: String?
            let analystKey: String?

            init(date: String? = nil, analystKey: String? = nil) {
                self.date = date
                self.analystKey = analystKey
            }
        }

        private let query: Query
        init(_ query: Query = Query()) {
            self.query = query
        }

        // MARK: Response Models
        struct StockAnalysisInfo: Decodable {
            let version: String?
            let generatedAt: String?
            let analysts: [Analyst]?
            let comparisons: [Comparison]?
            let notes: [Note]?

            enum CodingKeys: String, CodingKey {
                case version
                case generatedAt = "generated_at"
                case analysts
                case comparisons
                case notes
            }
        }

        struct Analyst: Decodable {
            let key: String?
            let name: String?
            let description: String?
            
            var banner: String {
                switch self.key {
                case "li-shufang": return "lsf_banner"
                case "ruan-huici": return "rhc_banner"
                case "chen-kunjen": return "ckj_banner"
                case "cai-zhenghua": return "tzh_banner"
                default: return ""
                }
            }
        }

        struct Comparison: Decodable {
            let date: String?
            let note: String?
            let blocks: [Block]?
        }

        struct Note: Decodable {
            let date: String?
            let note: String?
            let blocks: [Block]?
            let analystKey: String?

            enum CodingKeys: String, CodingKey {
                case date
                case note
                case blocks
                case analystKey = "analyst_key"
            }
        }

        struct Block: Decodable {
            let type: BlockType?
            let content: String?
            let headers: [String]?
            let rows: [[String]]?
        }

        enum BlockType: String, Decodable {
            case markdown
            case table
        }
    }
}
