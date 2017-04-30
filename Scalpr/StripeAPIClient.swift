//
//  StripeAPIClient.swift
//  Scalpr
//
//  Created by Cameron Connor on 4/24/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import Foundation
import Stripe
import Alamofire

class StripeAPIClient: NSObject, STPBackendAPIAdapter {
    
    static let sharedClient = StripeAPIClient()
    let session: URLSession
    var baseURLString: String? = nil
    var defaultSource: STPCard? = nil
    var sources: [STPCard] = []
    
    let loginHelper = LoginHelper()
    
    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: configuration)
        super.init()
    }
    
    func decodeResponse(_ response: URLResponse?, error: NSError?) -> NSError? {
        if let httpResponse = response as? HTTPURLResponse
            , httpResponse.statusCode != 200 {
            return error
        }
        return error
    }
    
    func completeCharge(_ result: STPPaymentResult, amount: Int, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set baseURLString to your Heroku URL in CheckoutViewController.swift"
                ])
            completion(error)
            return
        }
        let path = "charge"
        let url = baseURL.appendingPathComponent(path)
        let params: [String: AnyObject] = [
            "source": result.source.stripeID as AnyObject,
            "amount": amount as AnyObject
        ]
        
//        let request = URLRequest.init(url, method: .POST, params: params)
//        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
//            DispatchQueue.main.async {
//                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
//                    completion(error)
//                    return
//                }
//                completion(nil)
//            }
//        }
//        task.resume()
    }
    
    @objc func retrieveCustomer(_ completion: @escaping STPCustomerCompletionBlock) {
        guard let key = Stripe.defaultPublishableKey() , !key.contains("#") else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set stripePublishableKey to your account's test publishable key in CheckoutViewController.swift"
                ])
            completion(nil, error)
            return
        }
        
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            // This code is just for demo purposes - in this case, if the example app isn't properly configured, we'll return a fake customer just so the app works.
            let customer = STPCustomer(stripeID: "cus_test", defaultSource: self.defaultSource, sources: self.sources)
            completion(customer, nil)
            return
        }
        
    
        let path = "stripe/retrieve_customer.php"
        let url = baseURL.appendingPathComponent(path)
   
        
        Alamofire.request(url, method: .post, parameters: nil, headers: MiscHelper.getSecurityHeader()).responseString { response in
            
            let URLresp = URLResponse(url: (response.response?.url)!, mimeType: response.response?.mimeType, expectedContentLength: Int((response.response?.expectedContentLength)!), textEncodingName: response.response?.textEncodingName)
            
            let deserializer = STPCustomerDeserializer(data: response.data, urlResponse: URLresp, error: response.result.error)
            
            if let error = deserializer.error {
                completion(nil, error)
                return
            } else if let customer = deserializer.customer {
                completion(customer, nil)
            }
            
        }

    }
    
    @objc func selectDefaultCustomerSource(_ source: STPSource, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            if let token = source as? STPToken {
                self.defaultSource = token.card
            }
            completion(nil)
            return
        }
        let path = "/customer/default_source"
        let url = baseURL.appendingPathComponent(path)
        let params = [
            "source": source.stripeID,
            ]
//        let request = URLRequest.request(url, method: .POST, params: params as [String : AnyObject])
//        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
//            DispatchQueue.main.async {
//                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
//                    completion(error)
//                    return
//                }
//                completion(nil)
//            }
//        }
//        task.resume()
    }
    
    @objc func attachSource(toCustomer source: STPSource, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            if let token = source as? STPToken, let card = token.card {
                self.sources.append(card)
                self.defaultSource = card
            }
            completion(nil)
            return
        }
        let path = "/customer/sources"
        let url = baseURL.appendingPathComponent(path)
        let params = [
            "source": source.stripeID,
            ]
//        let request = URLRequest.request(url, method: .POST, params: params as [String : AnyObject])
//        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
//            DispatchQueue.main.async {
//                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
//                    completion(error)
//                    return
//                }
//                completion(nil)
//            }
//        }
//        task.resume()
    }
    
}
