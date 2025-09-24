import Foundation

// MARK: - Network Errors

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case httpError(statusCode: Int)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Endpoint

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]?
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    init(path: String, method: HTTPMethod = .GET, queryItems: [URLQueryItem]? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
    
    var url: URL? {
        guard var components = URLComponents(string: "https://dog.ceo/api\(path)") else {
            return nil
        }
        
        if let queryItems = queryItems {
            components.queryItems = queryItems
        }
        
        return components.url
    }
}

// MARK: - URL Session Protocol

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Network Service Protocol

protocol NetworkServicing {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// MARK: - Network Service Implementation

final class NetworkService: NetworkServicing {
    private let session: URLSessionProtocol
    private let decoder: JSONDecoder
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }
            }
            
            // Decode response
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                return decodedResponse
            } catch {
                throw NetworkError.decodingError(error)
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}

// MARK: - Dog API Endpoints

extension Endpoint {
    /// Get all breeds
    static let allBreeds = Endpoint(path: "/breeds/list/all")
    
    /// Get random images for a breed
    static func randomBreedImages(breed: String, count: Int = 3) -> Endpoint {
        return Endpoint(path: "/breed/\(breed)/images/random/\(count)")
    }
    
    /// Get single random image for a breed  
    static func randomBreedImage(breed: String) -> Endpoint {
        return Endpoint(path: "/breed/\(breed)/images/random")
    }
    
    /// Get random images for a sub-breed
    static func randomSubBreedImages(breed: String, subBreed: String, count: Int = 3) -> Endpoint {
        return Endpoint(path: "/breed/\(breed)/\(subBreed)/images/random/\(count)")
    }
}
