//
//  LabelLinkCellWithIcon.swift
//  PDX Bus
//
//  Created by Andy Wallace on 7/12/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

import UIKit

@objcMembers
class LabelLinkCellWithIcon: UITableViewCell {
    var link: String?

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure for selected state if needed
    }

    static func dequeue(
        from tableView: UITableView,
        imageNamed imageName: String?,
        title text: String,
        namedLink: String
    ) -> LabelLinkCellWithIcon {

        return dequeue(
            from: tableView,
            imageNamed: imageName,
            title: text,
            link: WebViewController.namedURL(namedLink)
        )
    }

    func config(
        text: String
    ) -> UIListContentConfiguration {
        var config = UIListContentConfiguration.subtitleCell()
        config.text = text
        config.secondaryText = link

        config.textProperties.font = UIFont.basic
        config.secondaryTextProperties.color = .systemBlue

        config.textProperties.numberOfLines = 0
        config.secondaryTextProperties.numberOfLines = 0

        config.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 10,
            leading: 16,
            bottom: 10,
            trailing: 16
        )
        return config
    }

    func styles(link: String?, alwaysSelectable: Bool) {
        if link != nil {
            self.accessoryType = .disclosureIndicator
            self.selectionStyle = .blue
        } else if alwaysSelectable {
            self.selectionStyle = .blue
            self.accessoryType = .none
        } else {
            self.accessoryType = .none
            self.selectionStyle = .none
        }
    }

    func update(
        boxedIcon: BoxedIcon,
        title text: String,
        namedLink: String?,
        alwaysSelectable: Bool = false
    ) {
        self.link = WebViewController.namedURL(namedLink)
        var config = self.config(text: text)
        config.image = boxedIcon.image()
        config.imageProperties.tintColor = boxedIcon.tint()
        self.contentConfiguration = config

        self.styles(link: link, alwaysSelectable: alwaysSelectable)

    }

    func update(
        imageNamed imageName: String?,
        title text: String,
        link: String?,
        alwaysSelectable: Bool = false
    ) {
        self.link = link
        var config = self.config(text: text)

        let boxed = Icons.assetOrSystemBoxedIcon(imageName)

        if let boxed = boxed {
            config.image = boxed.image()
            config.imageProperties.tintColor = boxed.tint()
        }

        self.contentConfiguration = config

        self.styles(link: link, alwaysSelectable: alwaysSelectable)

    }

    static func dequeue(
        from tableView: UITableView,
        imageNamed imageName: String?,
        title text: String,
        link: String?
    ) -> LabelLinkCellWithIcon {

        let cellId = "link"
        let cell =
            tableView.dequeueReusableCell(withIdentifier: cellId)
            as? LabelLinkCellWithIcon
            ?? LabelLinkCellWithIcon(style: .default, reuseIdentifier: cellId)

        cell.update(imageNamed: imageName, title: text, link: link)

        return cell
    }
}
