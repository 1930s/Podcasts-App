import Foundation
import Alamofire

class APIService
{
    static let shared = APIService()
    private init() { }
    
    func fetchPodcast(searchText: String, completion: @escaping ([Podcast]) -> Void)
    {
        let url = "https://itunes.apple.com/search"
        let parameters = ["term": searchText, "media": "podcast"]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseData { (dataResponse) in
                if let err = dataResponse.error
                {
                    print("Failed to contact ", err)
                    return
                }
                
                guard let data = dataResponse.data else { return }
                
                do
                {
                    let searchResults = try JSONDecoder().decode(SearchResults.self, from: data)
                    completion(searchResults.results)
                } catch let decodeErr {
                    print("Failed to decode: ", decodeErr)
                }
        }
    }
    
    func fetchEpisodes(forPodcast rssUrl: String, completion: @escaping (FeedResponse) -> Void)
    {
        let url = "https://api.rss2json.com/v1/api.json"
        let parameters = [
            "rss_url" : rssUrl,
            "api_key" : "xxqfpf12qwnled9dz1bri3ezzgwce9ri8wx6z0lc",
            "count": 1000
            ] as [String : Any]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseData { (dataResponse) in
                if let err = dataResponse.error
                {
                    print("Failed to contact ", err)
                    return
                }
                
                guard let data = dataResponse.data else { return }
                
                do
                {
                    let episodesResults = try JSONDecoder().decode(FeedResponse.self, from: data)
                    completion(episodesResults)
                } catch let decodeErr {
                    print("Failed to decode: ", decodeErr)
                }
        }
    }
    
    func downloadEpisode(episode: Episode, completion: @escaping (_ fileLocation: String) -> Void)
    {
//        print("Downloading Episode in API Service with url: \(episode.enclosure?.link)")
        guard let url = episode.enclosure?.link else {
            return
        }
        
        let downloadRequest = DownloadRequest.suggestedDownloadDestination()
        
        Alamofire.download(url, to: downloadRequest)
            .downloadProgress { (progress) in
            print(progress.fractionCompleted)
            }.response { (response) in
                guard let fileLocation = response.destinationURL else { return }
                guard let baseLocation = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                
                let fileName = fileLocation.lastPathComponent
                let completeFilePath = "\(baseLocation.absoluteString)\(fileName)"
                print(completeFilePath)
                
                completion(completeFilePath)
        }
    }
}

struct FeedResponse : Codable
{
    let items: [Episode]
}
