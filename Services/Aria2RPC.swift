import SwiftUI

enum Param: Codable {
    case string(String)
    case int(Int)
    case arr(Array<String>)
    
    init(from decoder: Decoder) throws {
        if let intValue = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(intValue)
            return
        }
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(stringValue)
            return
        }
        throw NSError()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .int(let int):
            try container.encode(int)
        case .arr(let arr):
            try container.encode(arr)
        }
    }
}


struct RPCRequest: Codable {
    let jsonrpc: String
    let id: String
    let method: String
    let params: [Param]
}

struct GlobalStatResponse: Codable {
    struct Result: Codable {
        let downloadSpeed: String
        let uploadSpeed: String
        let numActive: String
        let numWaiting: String
        let numStopped: String
        let numStoppedTotal: String
    }
    
    let id: String
    let jsonrpc: String
    let result: Result
}

struct File: Codable, Identifiable {
    var id = UUID()
    let completedLength: String
    let index: String
    let length: String
    let path: String
    let selected: String
    let uris: [Uri]
    
    struct Uri: Codable {
        let status: String
        let uri: String
    }
    
    enum CodingKeys: String, CodingKey {
        case completedLength, index, length, path, selected, uris
    }
}

struct TaskObject: Codable, Identifiable {
    var id = UUID()
    let bitfield: String?
    let completedLength: String
    let connections: String
    let downloadSpeed: String
    let files: [File]?
    let gid: String
    let status: String
    let totalLength: String
    let uploadSpeed: String
    
    enum CodingKeys: String, CodingKey {
        case completedLength, totalLength, files, uploadSpeed, downloadSpeed, connections, gid, status, bitfield
    }
}

struct Aria2Response: Codable {
    let result: [TaskObject]
}

struct TellStatusResponse: Codable {
    let result: TaskObject
}

class Aria2API: ObservableObject {
    @AppStorage("serverAddress") var serverAddress: String = ""
    @AppStorage("token") var token: String = ""
    
    func callRPCMethod(method: String, params: [Any]) async throws -> Data {
        let convertedParams = params.map { param in
            if let intParam = param as? Int {
                return Param.int(intParam)
            } else if let stringParam = param as? String {
                return Param.string(stringParam)
            } else if let arrParam = param as? Array<String> {
                return Param.arr(arrParam)
            } else {
                fatalError("Unsupported param type!")
            }
        }
        let rpcRequest = RPCRequest(jsonrpc: "2.0", id: "1", method: method, params: [Param.string("token:"+token)] + convertedParams)
        let url = URL(string: serverAddress)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        guard let payload = try? encoder.encode(rpcRequest) else {
            throw NSError()
        }
//        print("rpcRequest", url, String(data: payload, encoding: .utf8)!)
        request.httpBody = payload
        let (data, _) = try await URLSession.shared.data(for: request)
        let string = String(data: data, encoding: .utf8)
        print(string ?? "Data could not be converted to string")
        return data
    }
    func addUri(urls: [String]) async throws {
        _ = try await self.callRPCMethod(method: "aria2.addUri", params: [urls])
    }
    func getGlobalStat() async throws -> GlobalStatResponse.Result {
        let data = try await self.callRPCMethod(method: "aria2.getGlobalStat", params: [])
        let decoder = JSONDecoder()
        let response = try decoder.decode(GlobalStatResponse.self, from: data)
        return response.result
    }
    func tellActive() async throws -> [TaskObject]  {
        let data = try await self.callRPCMethod(method: "aria2.tellActive", params: [])
        let decoder = JSONDecoder()
        let response = try decoder.decode(Aria2Response.self, from: data)
        return response.result
    }
    
    func tellWaiting() async throws -> [TaskObject]  {
        let data = try await self.callRPCMethod(method: "aria2.tellWaiting", params: [-1,1000])
        let decoder = JSONDecoder()
        let response = try decoder.decode(Aria2Response.self, from: data)
        return response.result
    }
    func tellStopped() async throws -> [TaskObject] {
        let data = try await self.callRPCMethod(method: "aria2.tellStopped", params: [-1,1000])
        let decoder = JSONDecoder()
        let response = try decoder.decode(Aria2Response.self, from: data)
        return response.result
    }
    func tellStatus(gid: String) async throws -> TaskObject {
        let data = try await self.callRPCMethod(method: "aria2.tellStatus", params: [gid])
        let decoder = JSONDecoder()
        let response = try decoder.decode(TellStatusResponse.self, from: data)
        return response.result
    }
    func pause(gid: String) async throws {
        _ = try await self.callRPCMethod(method: "aria2.pause", params: [gid])
    }
    func pauseAll() async throws {
        _ = try await self.callRPCMethod(method: "aria2.pauseAll", params: [])
    }
    func resume(gid: String) async throws {
        _ = try await self.callRPCMethod(method: "aria2.unpause", params: [gid])
    }
    
}
