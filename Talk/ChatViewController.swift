import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class ChatViewController: UIViewController, View {
    typealias Reactor = ChatReactor

    @IBOutlet private weak var unitySceneView: UIView!
    @IBOutlet private weak var messageView: UIView!
    @IBOutlet private weak var messageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var bottomInputAreaConstraint: NSLayoutConstraint!

    var disposeBag = DisposeBag()
    var reactor: ChatReactor

    let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: nil, action: nil)

    private let messageViewtapGesture = UITapGestureRecognizer()
    // UnityのViewの読み込み
    private let unityView = Unity.shared.view

    init(reactor: ChatReactor) {
        self.reactor = reactor
        super.init(nibName: "ChatViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        messageViewtapGesture.cancelsTouchesInView = false
        messageView.addGestureRecognizer(messageViewtapGesture)
        setUpLayout()
        bind(reactor: reactor)
        configureKeyboardObservers()
        unitySceneView.addSubview(unityView)
        unityView.frame = unitySceneView.frame
    }

    func bind(reactor: ChatReactor) {
        settingsButton.rx.tap
            .throttle(.milliseconds(300), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                let talkSettingsViewController = TalkSettingsViewController()
                self?.navigationController?.pushViewController(talkSettingsViewController, animated: true)
            })
            .disposed(by: disposeBag)

        sendButton.rx.tap
            .throttle(.milliseconds(300), latest: false, scheduler: MainScheduler.instance)
            .withLatestFrom(textField.rx.text.orEmpty)
            .do(onNext: { [weak self] _ in
                self?.textField.text = ""
                self?.sendButton?.isEnabled = false
            })
            .map { Reactor.Action.askChatGPT($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        textField.rx.text.orEmpty
            .map { !$0.isEmpty }
            .subscribe(onNext: { isEnabled in
                self.sendButton?.isEnabled = isEnabled
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.messages }
            .bind(to: tableView.rx.items) { tableView, index, message in
                let indexPath = IndexPath(row: index, section: 0)
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath)
                if let chatCell = cell as? ChatMessageCell {
                    chatCell.configure(with: message)
                }
                cell.selectionStyle = .none
                cell.backgroundColor = .clear
                return cell
            }
            .disposed(by: disposeBag)

        reactor.state.map { $0.alert }
            .distinctUntilChanged()
            .filter { $0 != nil }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.showAlert(message: reactor.currentState.alert)
                reactor.action.onNext(.hideAlert)
            })
            .disposed(by: disposeBag)

        messageViewtapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)

        tableView.rx.willDisplayCell
            .subscribe(onNext: {[weak self] _ in
                self?.scrollToBottom()
            })
            .disposed(by: disposeBag)
    }

    private func setUpLayout() {
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none

        navigationItem.rightBarButtonItem = settingsButton
    }

    private func showAlert(message: String?) {
        guard let message = message else { return }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func scrollToBottom() {
        guard tableView.numberOfSections > 0 else {
            return
        }

        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1

        guard lastRow >= 0 else {
            return
        }

        let lastIndexPath = IndexPath(row: lastRow, section: lastSection)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }

    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }

        let keyboardHeight = keyboardFrame.height

        UIView.animate(withDuration: duration, animations: {
            self.bottomInputAreaConstraint.constant = keyboardHeight - 60
            self.view.layoutIfNeeded()
        })
    }

    @objc private func keyboardWillHide(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }

        UIView.animate(withDuration: duration, animations: {
            self.bottomInputAreaConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
}
