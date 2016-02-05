import Quick
import Nimble
import MoyaX
import Result
import Foundation

final class NetworkLogginPluginSpec: QuickSpec {
    override func spec() {
        let testStreamRequest = NSMutableURLRequest(URL: NSURL(string: url(GitHub.Zen))!)
        testStreamRequest.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        testStreamRequest.HTTPBodyStream = NSInputStream(data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!)

        let testBodyRequest = NSMutableURLRequest(URL: NSURL(string: url(GitHub.Zen))!)
        testBodyRequest.allHTTPHeaderFields = ["Content-Type" : "application/json"]
        testBodyRequest.HTTPBody = "cool body".dataUsingEncoding(NSUTF8StringEncoding)


        var log = ""
        let plugin = NetworkLoggerPlugin(verbose: true, output: { printing in
            //mapping the Any... from items to a string that can be compared
            let stringArray: [String] = printing.items.map { $0 as? String }.flatMap { $0 }
            let string: String = stringArray.reduce("") { $0 + $1 + " " }
            log += string
        })

        let pluginWithResponseDataFormatter = NetworkLoggerPlugin(verbose: true, output: { printing in
            //mapping the Any... from items to a string that can be compared
            let stringArray: [String] = printing.items.map { $0 as? String }.flatMap { $0 }
            let string: String = stringArray.reduce("") { $0 + $1 + " " }
            log += string
            }, responseDataFormatter: { _ in
                return "formatted body".dataUsingEncoding(NSUTF8StringEncoding)!
        })

        beforeEach {
            log = ""
        }

        it("outputs all request fields with body") {

            plugin.willSendRequest(testBodyRequest, target: GitHub.Zen)

            expect(log).to( contain("Request:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body: cool body") )
        }

        it("outputs all request fields with stream") {

            plugin.willSendRequest(testStreamRequest, target: GitHub.Zen)

            expect(log).to( contain("Request:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("Request Headers: [\"Content-Type\": \"application/json\"]") )
            expect(log).to( contain("HTTP Request Method: GET") )
            expect(log).to( contain("Request Body Stream:") )
        }

        it("outputs the reponse data") {
            let response = Response(statusCode: 200, data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!, response: NSURLResponse(URL: NSURL(string: url(GitHub.Zen))!, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<MoyaX.Response, MoyaX.Error> = .Success(response)

            plugin.didReceiveResponse(result, target: GitHub.Zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("cool body") )
        }

        it("outputs the formatted response data") {
            let response = Response(statusCode: 200, data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!, response: NSURLResponse(URL: NSURL(string: url(GitHub.Zen))!, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil))
            let result: Result<MoyaX.Response, MoyaX.Error> = .Success(response)

            pluginWithResponseDataFormatter.didReceiveResponse(result, target: GitHub.Zen)

            expect(log).to( contain("Response:") )
            expect(log).to( contain("{ URL: https://api.github.com/zen }") )
            expect(log).to( contain("formatted body") )
        }

        it("outputs an empty reponse message") {
            let response = Response(statusCode: 200, data: "cool body".dataUsingEncoding(NSUTF8StringEncoding)!, response: nil)
            let result: Result<MoyaX.Response, MoyaX.Error> = .Failure(MoyaX.Error.Data(response))

            plugin.didReceiveResponse(result, target: GitHub.Zen)

            expect(log).to( contain("Response: Received empty network response for Zen.") )
        }
    }
}
