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
        systemImage: Bool,
        title text: String,
        namedLink: String
    ) -> LabelLinkCellWithIcon {

        return dequeue(
            from: tableView,
            imageNamed: imageName,
            systemImage: systemImage,
            title: text,
            link: WebViewController.namedURL(namedLink)
        )
    }

    static func dequeue(
        from tableView: UITableView,
        imageNamed imageName: String?,
        systemImage: Bool,
        title text: String,
        link: String?
    ) -> LabelLinkCellWithIcon {

        let cellId = "link"
        let cell =
            tableView.dequeueReusableCell(withIdentifier: cellId)
            as? LabelLinkCellWithIcon
            ?? LabelLinkCellWithIcon(style: .subtitle, reuseIdentifier: cellId)

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

        // Handle image (deferred only if needed)
        if var name = imageName {
            var isSystem = systemImage
            if name.first == "!" {
                name.removeFirst()
                isSystem = true
            }

            if isSystem {
                config.image = UIImage(systemName: name)
                cell.contentConfiguration = config
            } else {
                // Defer setting contentConfiguration until async icon is loaded
                Icons.getDelayedIcon(name) { image in
                    var asyncConfig = config
                    asyncConfig.image = image
                    cell.contentConfiguration = asyncConfig
                }
            }
        } else {
            cell.contentConfiguration = config
        }
        
        if link != nil {
            cell.accessoryType = .disclosureIndicator;
        } else {
            cell.accessoryType = .none;
        }
        cell.link = link
        return cell
    }
}
