//
//  ViewController.swift
//  RxAlamofire
//
//  Created by Christoph Muck on 08/22/2017.
//  Copyright (c) 2017 Christoph Muck. All rights reserved.
//

import UIKit
import RxAlamofire
import RxSwift

class ViewController: UIViewController {

    var requestMaker: RequestMaker!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let factory = RequestMakerFactory(baseUrl: "https://jsonplaceholder.typicode.com")
        requestMaker = factory.createInstance()
        
        getUsers().asObservable()
            .flatMap{ Observable.from($0) }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getUsers() -> Single<[User]> {
        return requestMaker.request(RequestSpecification(
            path: "/users", method: .get
        )).decodeFromJson()
    }
}

struct User: Codable {
    
    let id: Int
    let name: String
    let username: String
    let email: String
}
