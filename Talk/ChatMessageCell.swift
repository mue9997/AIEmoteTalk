import UIKit

class ChatMessageCell: UITableViewCell {
    private let messageBubble: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(messageBubble)
        messageBubble.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: messageBubble.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: messageBubble.trailingAnchor, constant: -8),
            messageLabel.topAnchor.constraint(equalTo: messageBubble.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: messageBubble.bottomAnchor, constant: -8)
        ])
    }

    func configure(with chatGPTMessage: ChatGPTMessage) {
        var roleText: String
        if chatGPTMessage.role == .user {
            roleText = "【You】"
            messageBubble.layer.borderColor = UIColor.lightGray.cgColor
            messageLabel.textColor = .white
        } else {
            roleText = "【AI】"
            messageBubble.layer.borderColor = UIColor.white.cgColor
            messageLabel.textColor = .white
        }

        messageLabel.text = roleText + "\n" + chatGPTMessage.content.message
        messageBubble.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        messageBubble.layer.borderWidth = 1
        messageBubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        messageBubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: 8).isActive = true
        messageBubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        messageBubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        messageBubble.leadingAnchor.constraint(greaterThanOrEqualTo: messageLabel.leadingAnchor, constant: -8).isActive = true

        let maxWidth = contentView.frame.width
        let messageSize = messageLabel.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        messageLabel.preferredMaxLayoutWidth = messageSize.width

        backgroundColor = .clear
    }
}
