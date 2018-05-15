//
//  DictionaryChange.swift
//  BroadcastingCollections
//
//  Created by Óscar Morales Vivó
//  Copyright © 2018 Óscar Morales Vivó. All rights reserved.
//  MIT license, http://www.opensource.org/licenses/mit-license.php
//

import Foundation


public typealias DictionaryChange<Key: Hashable, Value> = CollectionChange<Dictionary<Key, Value>>

//  TODO: Compose/decompose, additional semantics (replacement).
