import UIKit
import RxCocoa
import RxSwift

class TalkSettingsViewController: UIViewController {

    @IBOutlet private weak var tokenTextField: UITextField!
    @IBOutlet private weak var charactorSettingTextField: UITextField!

    private let disposeBag = DisposeBag()
    private let chatGPTTokenKey = "chatGPTTokenKey"
    private let characterSettingKey = "characterSettingKey"

    override func viewDidLoad() {
        super.viewDidLoad()

        if let token = getToken() {
            tokenTextField.text = token
        }

        if let charactorSetting = getCharactorSetting() {
            charactorSettingTextField.text = charactorSetting
        }

        setupNavigationBar()
    }

    private func setupNavigationBar() {
        let saveButton = UIBarButtonItem(title: "保存", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = saveButton

        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveButtonTapped()
            })
            .disposed(by: disposeBag)
    }

    private func saveButtonTapped() {
        guard let token = tokenTextField.text, !token.isEmpty else {
            showAlert(message: "OpenAIのトークンを入力してください")
            return
        }

        guard let charactorSetting = charactorSettingTextField.text, !charactorSetting.isEmpty else {
            showAlert(message: "キャラクターの設定を入力してください")
            return
        }

        saveToken(token)
        saveCharactorSetting(charactorSetting)
        navigationController?.popViewController(animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: chatGPTTokenKey)
    }

    private func saveCharactorSetting(_ charactorSetting: String) {
        UserDefaults.standard.set(charactorSetting, forKey: characterSettingKey)
    }

    public func getToken() -> String? {
        return UserDefaults.standard.string(forKey: chatGPTTokenKey)
    }

    public func getCharactorSetting() -> String? {
        return UserDefaults.standard.string(forKey: characterSettingKey)
    }
}
