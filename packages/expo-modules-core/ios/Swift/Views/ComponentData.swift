// Copyright 2021-present 650 Industries. All rights reserved.

import React

@propertyWrapper
public final class Event {
  public var wrappedValue: AnyCallback

  public init<CallbackType: AnyCallback>(wrappedValue: CallbackType = CallbackType()) {
    self.wrappedValue = wrappedValue
  }

  internal func settle(_ handler: @escaping AnyCallbackHandlerType) {
    if let callback = wrappedValue as? AnyCallbackInternal {
      callback.settle(handler)
    }
  }
}

@objc(EXComponentData)
public final class ComponentData: RCTComponentData {
  /**
   Weak pointer to the holder of a module that the component data was created for.
   */
  weak var moduleHolder: ModuleHolder?

  /**
   Initializer that additionally takes the original view module to have access to all its informations.
   */
  @objc
  public init(viewModule: ViewModuleWrapper, managerClass: ViewModuleWrapper.Type, bridge: RCTBridge) {
    self.moduleHolder = viewModule.wrappedModuleHolder
    super.init(managerClass: managerClass, bridge: bridge)
  }

  // MARK: RCTComponentData

  /**
   Creates a setter for the specific prop. For non-event props we just let React Native do its job.
   Events are handled differently to conveniently use them in Swift.
   */
  public override func createPropBlock(_ propName: String, isShadowView: Bool) -> RCTPropBlockAlias {
    if isShadowView {
      return super.createPropBlock(propName, isShadowView: isShadowView)
    }
    if moduleHolder?.viewManager?.eventNames.contains(propName) == true {
      let bridge = self.manager?.bridge

      return { [weak bridge] (target: RCTComponent, value: Any) in
        let child = Mirror(reflecting: target).children.first {
          $0.label == "_\(propName)"
        }
        guard let event = child?.value as? Event else {
          return
        }

        event.settle { [weak target] (body: Any) in
          if let target = target {
            let componentEvent = RCTComponentEvent(name: propName, viewTag: target.reactTag, body: ["@@": body])
            bridge?.eventDispatcher().send(componentEvent)
          }
        }
      }
    }
    return super.createPropBlock(propName, isShadowView: isShadowView)
  }

  /**
   The base `RCTComponentData` class does some Objective-C dynamic calls in this function, but we don't
   need to do these slow operations since the Sweet API gives us necessary details without reflections.
   */
  public override func viewConfig() -> [String: Any] {
    var propTypes: [String: Any] = [:]
    var directEvents: [String] = []
    let superClass: AnyClass? = managerClass.superclass()

    if let eventNames = moduleHolder?.viewManager?.eventNames {
      for eventName in eventNames {
        directEvents.append(normalizeEventName(eventName))
        propTypes[eventName] = "BOOL"
      }
    }

    return [
      "propTypes": propTypes,
      "directEvents": directEvents,
      "bubblingEvents": [String](),
      "baseModuleName": superClass?.moduleName() as Any
    ]
  }
}

fileprivate func normalizeEventName(_ eventName: String) -> String {
  if eventName.hasPrefix("on") {
    return "top".appending(eventName.dropFirst(2))
  }
  if !eventName.hasPrefix("top") {
    return "top"
      .appending(eventName.first?.uppercased() ?? "")
      .appending(eventName.dropFirst())
  }
  return eventName;
}
