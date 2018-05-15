//
//  ErrorReporter.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import os
import Foundation


//  Utility for blowing up reporting. Can be set to NOT blow up for testing purposes.
final public class ErrorReporter {

    static public var testingMode: Bool = false


    static public var testingLog: String = ""


    public class func report(_ errorMessage: String, _ params: Any...) {
        if testingMode {
            testingLog += String(describing: errorMessage + "\n")
        } else {
            preconditionFailure(String(format: errorMessage, params))
        }
    }
}
