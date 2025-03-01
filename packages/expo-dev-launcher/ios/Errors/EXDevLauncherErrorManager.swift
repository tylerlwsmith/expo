// Copyright 2015-present 650 Industries. All rights reserved.

import Foundation

@objc
public class EXDevLauncherErrorManager: NSObject {
  internal weak var controller: EXDevLauncherController?
  private weak var currentVC: EXDevLauncherErrorViewController?
  private var error: EXDevLauncherAppError?
  
  @objc
  public init(controller: EXDevLauncherController) {
    self.controller = controller
    EXDevLauncherRedBoxInterceptor.isInstalled = true
  }
    
  @objc
  public func consumeError() -> EXDevLauncherAppError {
    let result = error!
    error = nil
    return result
  }
  
  @objc
  public func showError(_ error: EXDevLauncherAppError) {
    guard let nextViewController = getNextErrorViewController() else {
      currentVC = nil
      return
    }
    
    self.error = error
    currentVC = nextViewController
    controller?.currentWindow()?.rootViewController = currentVC
  }
  
  private func getNextErrorViewController() -> EXDevLauncherErrorViewController? {
    if currentVC == nil || controller?.currentWindow()?.rootViewController != currentVC {
      return EXDevLauncherErrorViewController.create(forManager: self)
    }
    
    return currentVC
  }
}
