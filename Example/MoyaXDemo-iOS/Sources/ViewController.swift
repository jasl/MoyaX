import UIKit
import MoyaX

class ViewController: UITableViewController {
    let provider = MoyaXGenericProvider<GitHub>()
    var repositories = [Repository]()

    override func viewDidLoad() {
        super.viewDidLoad()

        downloadRepositories("ashfurrow")
    }

    // MARK: - API Stuff

    func downloadRepositories(username: String) {
        self.provider.request(.UserRepositories(username), completion: { result in

            var success = true
            var message = "Unable to fetch from GitHub"

            switch result {
            case let .Response(response):
                do {
                    guard let json = try response.mapJSON() as? [[String: AnyObject]] else {
                        success = false
                        break
                    }

                    self.repositories = [Repository](byArray: json)
                } catch {
                    success = false
                }

                self.tableView.reloadData()
            case let .Incomplete(error):
                guard let error = error as? CustomStringConvertible else {
                    break
                }
                message = error.description
                success = false
            }

            if !success {
                let alertController = UIAlertController(title: "GitHub Fetch", message: message, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    alertController.dismissViewControllerAnimated(true, completion: nil)
                })
                alertController.addAction(ok)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }

    func downloadZen() {
        self.provider.request(.Zen, completion: { result in
            var message = "Couldn't access API"
            if case let .Response(response) = result {
                message = (try? response.mapString()) ?? message
            }

            let alertController = UIAlertController(title: "Zen", message: message, preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                alertController.dismissViewControllerAnimated(true, completion: nil)
            })
            alertController.addAction(ok)
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }

    // MARK: - User Interaction

    @IBAction func searchWasPressed(sender: UIBarButtonItem) {
        var usernameTextField: UITextField?

        let promptController = UIAlertController(title: "Username", message: nil, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            if let usernameTextField = usernameTextField {
                self.downloadRepositories(usernameTextField.text!)
            }
        })
        _ = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in }
        promptController.addAction(ok)
        promptController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            usernameTextField = textField
        }

        presentViewController(promptController, animated: true, completion: nil)
    }

    @IBAction func zenWasPressed(sender: UIBarButtonItem) {
        downloadZen()
    }

    // MARK: - Table View

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.repositories.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let repository = self.repositories[indexPath.row]
        (cell.textLabel as UILabel!).text = repository.name

        return cell
    }
}
