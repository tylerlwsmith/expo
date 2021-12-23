// Copyright 2021-present 650 Industries. All rights reserved.

typealias AnyCallbackHandlerType = (Any) -> Void

public protocol AnyCallback {
  init()
}

internal protocol AnyCallbackInternal: AnyCallback {
  func settle(_ handler: @escaping AnyCallbackHandlerType)
}

/**
 Callable object that represents a JavaScript function.
 */
public class Callback<ArgType>: AnyArgument, AnyCallbackInternal {
  private var argumentType = ArgumentType(ArgType.self)

  private var handler: AnyCallbackHandlerType?

  // MARK: AnyCallback

  required public init() {}

  // MARK: AnyCallbackInternal

  internal func settle(_ handler: @escaping AnyCallbackHandlerType) {
    self.handler = handler
  }

  // MARK: Calling as function

  /**
   Allows the callback instance to be called as a function.
   */
  public func callAsFunction(_ arg: ArgType) {
    handler?(arg as Any)
  }
}
