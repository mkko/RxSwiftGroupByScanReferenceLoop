//
//  ViewController.swift
//  RxSwiftMemLeak
//
//  Created by Mikko Välimäki on 2018-12-30.
//  Copyright © 2018 Mikko. All rights reserved.
//

import UIKit
import RxSwift

class IntListener {
    let key: Int
    private let disposeBag = DisposeBag()
    init(key: Int, updates: Observable<Int>) {
        self.key = key
        updates
            .debug("IntListener.updates(\(key))")
            .subscribe()
            .disposed(by: disposeBag)
    }

    deinit {
        print("---- Killed IntListener(\(key))")
    }
}

class ViewController: UIViewController {

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let activeToggle = Observable<Int>
            .interval(5, scheduler: MainScheduler.instance)
            .startWith(0)
            .map { $0 % 2 == 0}
        let someProducer = Observable<Int>
            .interval(1, scheduler: MainScheduler.instance)
            .startWith(0)

        activeToggle
            .flatMapLatest { isActive -> Observable<[IntListener]> in
                if isActive {
                    return someProducer
                        .groupBy(keySelector: { $0 % 3 })
                        .scan([], accumulator: { (acc, g) in
                            acc + [IntListener(key: g.key, updates: g.asObservable())]
                        })
                } else {
                    return .just([])
                }
            }
            .debug("-----")
            .subscribe()
            .disposed(by: disposeBag)

        // This works:
        //activeToggle
        //    .flatMapLatest { isActive -> Observable<[IntListener]> in
        //        if isActive {
        //            return someProducer
        //                .groupBy(keySelector: { _ in 0 })
        //                .map { g in
        //                    [IntListener(key: g.key, updates: g.asObservable())]
        //            }
        //        } else {
        //            return .just([])
        //        }
        //    }
        //    .debug("-----")
        //    .subscribe()
        //    .disposed(by: disposeBag)

        // This also works:
        //activeToggle
        //    .flatMapLatest { isActive -> Observable<[IntListener]> in
        //        if isActive {
        //            return someProducer
        //                .scan([], accumulator: { (acc, g) in
        //                    acc + [IntListener(key: g, updates: Observable<Int>.interval(1, scheduler: MainScheduler.instance))]
        //                })
        //        } else {
        //            return .just([])
        //        }
        //    }
        //    .debug("-----")
        //    .subscribe()
        //    .disposed(by: disposeBag)
    }


}

