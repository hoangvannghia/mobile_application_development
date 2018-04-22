//
//  ViewController.swift
//  Ex2
//
//  Created by hoang van nghia on 4/22/18.
//  Copyright © 2018 hoang van nghia. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
   private let bag = DisposeBag()
   private let worker = ApiWorker()
   
   private let usdRate = Variable<Double>(0.0)
   private let eurRate = Variable<Double>(0.0)
   private let error = PublishSubject<String>()
   @IBOutlet weak var usdRateLabel: UILabel!
   @IBOutlet weak var euroRateLabel: UILabel!
   @IBOutlet weak var picker: UIPickerView!
   
   @IBOutlet weak var toLabel: UILabel!
   @IBOutlet weak var fromLabel: UILabel!
   @IBOutlet weak var textField: UITextField!
   private var currentPickerIdx: Int = 0
   private var currentRate: Double {
      if currentPickerIdx == 0 {
         return usdRate.value
      } else if currentPickerIdx == 1 {
         return eurRate.value
      } else if currentPickerIdx == 2 {
         return 1.0 / usdRate.value
      } else {
         return 1.0 / eurRate.value
      }
   }
   
   private var currentToCur: String {
      if currentPickerIdx == 0 {
         return "VNĐ"
      } else if currentPickerIdx == 1 {
         return "VNĐ"
      } else if currentPickerIdx == 2 {
         return "💲"
      } else {
         return "€"
      }
   }
   
   private let rateLabels = ["💲 to VNĐ", "€ to VNĐ", "VNĐ to 💲", "VNĐ to €"]
   private let fromTitle = ["💲", "€", "VNĐ", "VNĐ"]
   override func viewDidLoad() {
      super.viewDidLoad()
      bind()
      
   }
   
   private func bind() {
      picker.dataSource = self
      picker.delegate = self
      
      Observable<Int>.interval(10, scheduler: MainScheduler.asyncInstance)
         .subscribe(onNext: { [weak self] _ in
            self?.getRates()
         }).disposed(by: bag)
      
      usdRate.asObservable().map({
         return $0 == 0.0 ? "Loading ..." : String.init(format: "%.2f", $0)
      }).bind(to: usdRateLabel.rx.text).disposed(by: bag)
   
      eurRate.asObservable().map({
         return $0 == 0.0 ? "Loading ..." : String.init(format: "%.2f", $0)
      }).bind(to: euroRateLabel.rx.text).disposed(by: bag)
      
      textField.rx.text.asObservable().filter({
         $0 == nil || $0 == ""
      }).bind(to: toLabel.rx.text).disposed(by: bag)
      
      
      Observable<Double>.combineLatest([
         eurRate.asObservable(),
         usdRate.asObservable()
         ]).subscribe(onNext: { [weak self] _ in
            self?.convert()
         }).disposed(by: bag)
      
      textField.delegate = self
      textField.rx.text.asObservable().subscribe(onNext: { [weak self] _ in
         self?.convert()
      }).disposed(by: bag)
      
      error.subscribe(onNext: { [weak self] error in
         let alert = UIAlertController(title: "Xảy ra lỗi", message: error, preferredStyle: .alert)
         let action = UIAlertAction(title: "OK", style: .default,
                                    handler: nil)
         alert.addAction(action)
         
         self?.present(alert, animated: true, completion: nil)
         
      }).disposed(by: bag)
      
      getRates()
   }

   
   private func getRates() {
      self.worker.getRates().done({ (rates) in
         self.usdRate.value = rates.usd
         self.eurRate.value = rates.eur
      }).catch({ [weak self] (error) in
         if let error = error as? ApiError {
            switch error {
            case .internet:
               self?.error.onNext("Internet error")
            case .server:
               self?.error.onNext("Lỗi server")
            }
         }
      })
   }
   
   private func convert() {
      let value = Double(textField.text ?? "0") ?? 0.0
      let text = "= \(String.init(format: "%.2f", value * currentRate)) \(currentToCur)"
      toLabel.text = text
   }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
   func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
      return 4
   }
   
   func numberOfComponents(in pickerView: UIPickerView) -> Int {
      return 1
   }
   
   func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
      return rateLabels[row]
   }
   
   func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
      fromLabel.text = fromTitle[row]
      currentPickerIdx = row
      convert()
   }
   
   func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
      let newStr = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
      let isNumber = Double.init(newStr) != nil
      
      return isNumber
   }
}










