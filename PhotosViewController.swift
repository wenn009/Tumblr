//
//  UserViewController.swift
//  Tumblr
//
//  Created by Wenn Huang on 1/31/17.
//  Copyright © 2017 Wenn Huang. All rights reserved.
//

import UIKit
import AFNetworking


class PhotosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var posts:[NSDictionary]?
    var isMoreDataLoading = false;
    var loadingMoreView: InfiniteScrollActivityView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 240
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)),for:UIControlEvents.valueChanged)
        
        tableView.insertSubview(refreshControl, at:0)
        
        networkrequest()
        
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        tableView.contentInset = insets
        
    }
    
    func networkrequest(){
    // Do any additional setup after loading the view.
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(configuration: URLSessionConfiguration.default,delegate:nil,
            delegateQueue:OperationQueue.main)

        let task : URLSessionDataTask = session.dataTask(with: request as URLRequest,completionHandler: { (data, response, error) in
        if let data = data {
            if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
    //print("responseDictionary: \(responseDictionary)")
    
    // Recall there are two fields in the response dictionary, 'meta' and 'response'.
    // This is how we get the 'response' field
                let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
    
    // This is where you will store the returned array of posts in your posts property
    //self.feeds = responseFieldDictionary["posts"] as! [NSDictionary]
                self.posts = responseFieldDictionary["posts"] as? [NSDictionary]
                //self.isMoreDataLoading = false
                self.tableView.reloadData()
            }
        }
        
        
        });
        task.resume()
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl){
        networkrequest()
        refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let posts = posts {
            return posts.count
        }
        else {
            return 0;
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "photoCell") as! photoCell
        
        let post = posts![indexPath.row]
        
        
        //let timestamp = post["timestamp"] as? String
        
        if let photos = post.value(forKeyPath: "photos") as? [NSDictionary] {
            // photos is NOT nil, go ahead and access element 0 and run the code in the curly braces
            let imageUrlString = photos[0].value(forKeyPath: "original_size.url") as? String
            
            if let imageUrl = URL(string: imageUrlString!) {
                // URL(string: imageUrlString!) is NOT nil, go ahead and unwrap it and assign it to imageUrl and run the code in the curly braces
                cell.feedImage.setImageWith(imageUrl)
            } else {
                // URL(string: imageUrlString!) is nil. Good thing we didn't try to unwrap it!
            }

        } else {
            // photos is nil. Good thing we didn't try to unwrap it!
        }
        
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView){
        if(!isMoreDataLoading){
            
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            if (scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging){
                isMoreDataLoading = true
                
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                
                loadMoreData()
            }
        }
        
    }
    
    func loadMoreData() {
        let url = URL(string:"https://api.tumblr.com/v2/blog/humansofnewyork.tumblr.com/posts/photo?api_key=Q6vHoaVm5L1u2ZAW1fqv3Jw48gFzYVg9P0vH0VHl3GVy6quoGV")
        let request = URLRequest(url: url!)
        let session = URLSession(configuration: URLSessionConfiguration.default,delegate:nil,
                                 delegateQueue:OperationQueue.main)
        
        let task : URLSessionDataTask = session.dataTask(with: request as URLRequest,completionHandler: { (data, response, error) in
            if let data = data {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
                    //print("responseDictionary: \(responseDictionary)")
                    self.isMoreDataLoading = false
                    self.loadingMoreView!.stopAnimating()
                    // Recall there are two fields in the response dictionary, 'meta' and 'response'.
                    // This is how we get the 'response' field
                    let responseFieldDictionary = responseDictionary["response"] as! NSDictionary
                    
                    // This is where you will store the returned array of posts in your posts property
                    //self.feeds = responseFieldDictionary["posts"] as! [NSDictionary]
                    self.posts = responseFieldDictionary["posts"] as? [NSDictionary]
                    //self.isMoreDataLoading = false
                    
                    self.tableView.reloadData()
                }
            }
            
            
        });
        task.resume()
        
    }



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UITableViewCell
    //let cell2 = tableView.dequeueReusableCell(withIdentifier: "photoCell") as! photoCell
        let indexPath = tableView.indexPath(for:cell)
        let post = posts![indexPath!.row]
        let vc = segue.destination as! PhotoDetailsViewController
        vc.post = post
    
    
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }

}
