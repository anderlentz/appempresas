//
//  HomeUIComposer.swift
//  EmpresasApp
//
//  Created by Anderson on 31/01/20.
//  Copyright © 2020 Anderson. All rights reserved.
//

import UIKit

public final class HomeUIComposer {
    static func loginComposedWith(viewModel: HomeViewModelProtocol, coordinator: HomeCoordinator) -> HomeViewController {
                
        let bundle = Bundle(for: HomeViewController.self)
        let storyboard = UIStoryboard(name: "Home",bundle: bundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        
        viewController.viewModel = viewModel
        viewController.navigationCoordinator = coordinator
        
        return viewController
    }
}
