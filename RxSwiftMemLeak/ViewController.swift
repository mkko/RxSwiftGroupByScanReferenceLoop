//
//  ViewController.swift
//  RxSwiftMemLeak
//
//  Created by Mikko Välimäki on 2018-12-30.
//  Copyright © 2018 Mikko. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

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

    private var disposeBag = DisposeBag()

    @IBOutlet weak var stopButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let _ = stopButton.rx
            .controlEvent(.touchUpInside)
            .subscribe(onNext: {
                self.disposeBag = DisposeBag()
            })

        let someProducer = Observable<Int>
            .interval(1, scheduler: MainScheduler.instance)
            .startWith(0)

        someProducer
            .debug("")
            .groupBy(keySelector: { $0 % 3 })
            .scan([], accumulator: { (acc, g) in
                acc + [IntListener(key: g.key, updates: g.asObservable())]
            })
            .debug("someProducer")
            .subscribe { e in
                print("e: \(e)")
            }
            .disposed(by: disposeBag)

        // This works:
        //someProducer
        //    .debug("")
        //    .groupBy(keySelector: { _ in 0 })
        //    .map { g in
        //        [IntListener(key: g.key, updates: g.asObservable())]
        //    }
        //    .debug("someProducer")
        //    .subscribe { e in
        //        print("e: \(e)")
        //    }
        //    .disposed(by: disposeBag)

        // This also works:
        //someProducer
        //    .debug("")
        //    .scan([], accumulator: { (acc, g) in
        //        acc + [IntListener(key: g, updates: Observable<Int>.interval(1, scheduler: MainScheduler.instance))]
        //    })
        //    .debug("someProducer")
        //    .subscribe { e in
        //        print("e: \(e)")
        //    }
        //    .disposed(by: disposeBag)
    }


}

