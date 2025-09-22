//
//  SceneDelegate.swift
//  TowCam
//
//  Created by Adib Triki on 21/09/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - Scene Connection
    
    /// Configuration initiale de la scène et de la fenêtre
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    // MARK: - Scene Lifecycle
    
    /// Fonction pour nettoyer les ressources lors de la déconnexion
    func sceneDidDisconnect(_ scene: UIScene) {
        
    }

    /// Fonction pour reprendre les tâches lors de l'activation de la scène
    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    /// Fonction pour mettre en pause les tâches lors de la désactivation
    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    /// Fonction pour restaurer l'état lors du passage en premier plan
    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }

    /// Fonction pour sauvegarder l'état lors du passage en arrière-plan
    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }
}
