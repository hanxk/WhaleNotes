//
//  EmojiRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift
import SwiftCSV

class EmojiRepo {
    
    static let shared = EmojiRepo()
    private let disposeBag = DisposeBag()
    
    private var categoryEmojis:[CategoryAndEmoji] = []
    
    func randomEmoji(callback:@escaping (Emoji)->Void) {
        self.loadEmojiFromCSV {
            let categary = $0[Int.random(in: 0..<$0.count)]
            let emoji = categary.emojis[Int.random(in: 0..<categary.emojis.count)]
            callback(emoji)
        }
    }
    
    func searchEmoji(keyword: String,callback:@escaping ([Emoji])->Void) {
        self.loadEmojiFromCSV {
            var searchedEmojis:[Emoji] = []
            for categoryEmoji in $0 {
                let emojis = categoryEmoji.emojis.filter { emoji in
                   return  emoji.keywords.joined(separator: " ").contains(keyword)
                }
                searchedEmojis.append(contentsOf: emojis)
            }

            callback(searchedEmojis)
        }
    }
    
    func loadEmojiFromCSV(callback:@escaping ([CategoryAndEmoji])->Void) {
        if categoryEmojis.count > 0 {
            callback(categoryEmojis)
            return
        }
        Observable<[CategoryAndEmoji]>.create {  observer -> Disposable in
            do {
                let emojis = try self.loadSmileysEmojis()
                observer.onNext(emojis)
                observer.onCompleted()
            }catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
        .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: {
            self.categoryEmojis = $0
            callback($0)
        }, onError: { err in
            print(err)
        }).disposed(by: disposeBag)
    }
}

extension EmojiRepo {
    private func loadSmileysEmojis() throws -> [CategoryAndEmoji] {
        let categories: [EmojiCategory] = [
            EmojiCategory(emoji: "😃", text: "Smileys & People",csvName: "emoji_smileys_people"),
            EmojiCategory(emoji: "🐻", text: "Animals & Nature",csvName: "emoji_animals_nature"),
            EmojiCategory(emoji: "🍔", text: "Food & Drink",csvName: "emoji_food_drink"),
            EmojiCategory(emoji: "⚽", text: "Activity",csvName: "emoji_activity"),
            EmojiCategory(emoji: "🌇", text: "Travel & Places",csvName: "emoji_travel_places"),
            EmojiCategory(emoji: "💡", text: "Objects",csvName: "emoji_objects"),
            EmojiCategory(emoji: "🔣", text: "Symbols",csvName: "emoji_symbols"),
            EmojiCategory(emoji: "🇨🇳", text: "Flags",csvName: "emoji_flags"),
        ]
        var results: [CategoryAndEmoji] = []
        for category in categories {
            let emojis = try loadEmojisFromCSV(csvName: category.csvName)
            results.append(CategoryAndEmoji(category: category, emojis: emojis))
        }
        return results
    }
    
    private func loadEmojisFromCSV(csvName: String) throws -> [Emoji] {
        var emojis:[Emoji] = []
        guard  let resource: CSV = try CSV(
            name: csvName,
            extension: "csv",
            bundle: .main,
            encoding: .utf8) else { return emojis }
        
        for row in resource.enumeratedRows {
            print(row[0])
            emojis.append(Emoji(value: row[0],
                                 keywords: [
                                    row[1].trimmingCharacters(in: .whitespaces),
                                    row[2].trimmingCharacters(in: .whitespaces)
                ]
            ))
        }
        return emojis
    }
    
}
