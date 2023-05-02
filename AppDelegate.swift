import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            // 初回起動時のみデフォルトのキャラクター設定を保存
        let characterSettingKey = "characterSettingKey"
            if UserDefaults.standard.string(forKey: characterSettingKey) == nil {
                let defaultCharacterSetting = "あなたは学校の後輩として振る舞ってください。あなたの性格は生意気ですが、先輩のことを信頼しています。ユーザーのことは先輩と呼んでください"
                UserDefaults.standard.set(defaultCharacterSetting, forKey: characterSettingKey)
            }

        // Unityを呼び出す
        Unity.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

            return true
        }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "AIEmoteTalk")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
