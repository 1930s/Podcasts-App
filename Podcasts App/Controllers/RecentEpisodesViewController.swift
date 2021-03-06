import UIKit
import SDWebImage

class RecentEpisodesViewController: UITableViewController
{
    private let cellId = "cellId"
    private var searchController: UISearchController?
    fileprivate let repo = PodcastsRepository()
    
    
    private var episodes = [Episode]()
    private var filtered = [Episode]()
    private var isSearching = false
    
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupNavigationbar()
        setupTableView()
        setupSearchBar()
        fetchEpisodes()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        fetchEpisodes()
    }
    
    fileprivate
    func setupTableView()
    {
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 40.0, right: 0)
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    fileprivate
    func setupSearchBar()
    {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    fileprivate
    func setupNavigationbar()
    {
        navigationController?.isNavigationBarHidden = false
    }
    
    
    fileprivate
    func fetchEpisodes()
    {
        episodes = repo.fetchAllRecentlyPlayedPodcasts() ?? episodes
        tableView.reloadData()
    }
}

// MARK: TableView methods
extension RecentEpisodesViewController
{
    override
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 110.0
    }
    
    override
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return isSearching ? filtered.count : episodes.count
    }
    
    override
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        cell.episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        guard let url = URL(string: cell.episode.imageUrl ?? "") else { return cell }
        cell.thumbnailImageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    override
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let episode = isSearching ? filtered[indexPath.row] : episodes[indexPath.row]
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: episode, playListEpisodes: self.episodes)
        
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        var episode = self.episodes[indexPath.row]
        let downloadAction = UITableViewRowAction(style: .normal, title: "Download") { (_, _) in
            
            // download the podcast episode using Alamofires
            APIService.shared.downloadEpisode(episode: episode, completion: { (fileLocation) in
                episode.enclosure?.link = fileLocation
                self.repo.downloadEpisode(episode: episode)
            })
        }
        return [downloadAction]
    }
    
    fileprivate
    func showPlayerDetailsView(withEpisode episode: Episode)
    {
        let window = UIApplication.shared.keyWindow
        let playerDetailsView = PlayerDetailsView.initFromNib()
        playerDetailsView.frame = self.view.frame
        playerDetailsView.episode = episode
//        playerDetailsView.thumbnail = podcast?.artworkUrl600
        
        UIView.animate(withDuration: 0.72) {
            window?.addSubview(playerDetailsView)
        }
    }
}

// MARK: Searchbar methods
extension RecentEpisodesViewController: UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        isSearching = searchText.count > 0
        
        filtered = self.episodes.filter { (episode) -> Bool in
            (episode.title?.lowercased().contains(searchText.lowercased())) ?? false
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        isSearching = false
    }
}
