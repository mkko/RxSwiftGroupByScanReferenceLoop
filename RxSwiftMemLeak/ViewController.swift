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

class Update {

    private let key: Int

    private let disposeBag = DisposeBag()

    init(key: Int, updates: Observable<Int>) {
        self.key = key
        updates
            .debug("Update(key: \(key))")
            .subscribe()
            .disposed(by: disposeBag)
    }

    deinit {
        print("Update(\(key)).deinit")
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

        // Create a couple of grouped observables.
        someProducer
            .groupBy(keySelector: { $0 % 3 })
            .scan([], accumulator: { (acc, g) in
                acc + [Update(key: g.key, updates: g.asObservable())]
            })
            .debug("Main")
            .subscribe()
            .disposed(by: disposeBag)

        // Make it stop after three seconds.
        Observable<Int>
            .interval(3, scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                print("Disposing...")
                self.disposeBag = DisposeBag()
            })
            .disposed(by: disposeBag)

        // This works:
        //someProducer
        //    .debug("")
        //    .groupBy(keySelector: { _ in 0 })
        //    .map { g in
        //        [Update(key: g.key, updates: g.asObservable())]
        //    }
        //    .debug("Main")
        //    .subscribe { e in
        //        print("e: \(e)")
        //    }
        //    .disposed(by: disposeBag)

        // This also works:
        //someProducer
        //    .debug("")
        //    .scan([], accumulator: { (acc, g) in
        //        acc + [Update(key: g, updates: someProducer)]
        //    })
        //    .debug("Main")
        //    .subscribe { e in
        //        print("e: \(e)")
        //    }
        //    .disposed(by: disposeBag)
    }


}

