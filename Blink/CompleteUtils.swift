//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////


import Foundation

struct CompleteToken {
  var range: Range<String.Index>
  var value: String = ""
  
  
  var quote: String.Element? = nil
  var isRedirect: Bool = false

  var prefix: String = ""
  // unquaoted query
  var query: String = ""
  
  // if cmd is detected
  var cmd: String? = nil
}

struct CompleteUtils {
  
  static func completeToken(_ input: String, cursor: Int) -> CompleteToken {
    if input.isEmpty {
      return CompleteToken(range: input.startIndex..<input.endIndex)
    }
    
    var buf = Array(input)
    var len = buf.count
    var cursor = max(min(cursor, len), 0)
    var start = 0;
    var end = 0;
    var i = 0;
    var qch: String.Element? = nil
    let quotes = "\"'"
    var bs = 0
    var isRedirect = false
    var pos = 0
    
    while i < cursor {
      defer { i += 1 }
      let ch = buf[i]
      
      if ch == "\\" {
        bs += 1
        continue
      }

      defer {
        bs = 0
      }
      
      if ch.isWhitespace {
        pos = i
      }
      
      if ch == "|" && bs % 2 == 0 {
        start = i
        pos = i
        isRedirect = false
        continue
      }
      
      if ch == ">" && bs % 2 == 0 {
        start = i
        pos = i
        isRedirect = true
        continue
      }
      
      for quote in quotes {
        if ch == quote && bs % 2 == 0 {
          qch = quote
          i += 1
          while i < cursor {
            defer { i += 1 }
            let c = buf[i]
      
            if c == "\\" {
              bs += 1
              continue
            }
            
            defer {
              bs = 0
            }

            if c == quote && bs % 2 == 0 {
              qch = nil
              break
            }
          }
          break
        }
      }
    }
    
    i = cursor
    while i < len {
      let ch = buf[i]
      
      if ch == "\\" {
        bs += 1
        i += 1
        continue
      }

      defer {
        bs = 0
      }
      
      // we are inside quotes
      if let quote = qch {
        if ch == quote && bs % 2 == 0 {
          i += 1
          break
        }
      } else if (ch.isWhitespace || ch == "|" || ch == ">") && bs % 2 == 0 {
        break
      }
      i += 1
    }
    end = i
    
    while start < end {
      let ch = buf[start]
      if ch == " " || ch == "|" || ch == ">" {
        start += 1
        continue
      }
      break
    }
    
    if start > pos {
      pos = start
    }
    
    while pos < cursor {
      let ch = buf[pos]
      if ch.isWhitespace {
        pos += 1
      } else {
        break
      }
    }
    
    
    let range = input.index(input.startIndex, offsetBy: start)..<input.index(input.startIndex, offsetBy: end)
    
//    if pos >= len {
//      pos = len - 1
//    }
//
//    if start >= len {
//      start = len - 1
//    }
    
    var cmd: String?
    var prefix: String
    var query = (cursor == 0 || pos >= len) ? "" : String(buf[pos..<cursor])
    
    query = query.replacingOccurrences(of: "\\\\", with: "\\")
    if let q = qch  {
      let qq = String(q)
      query = query.replacingOccurrences(of: "\\" + qq, with: qq)
      query.removeFirst()
    } else {
      query = query.replacingOccurrences(of: "\\ ", with: " ")
      if query.first == "\"" && query.last == "\"" {
        if query == "\"" {
          query = ""
        } else {
          query = query.replacingOccurrences(of: "\\\"", with: "\"")
          query.removeFirst()
          query.removeLast()
        }
        qch = Character("\"")
      } else if query.first == "'" && query.last == "'" {
        if query == "'" {
          query = ""
        } else {
          query = query.replacingOccurrences(of: "\\\'", with: "'")
          query.removeFirst()
          query.removeLast()
        }
        qch = Character("'")
      }
    }

    if pos == start || pos >= len {
      cmd = nil
      prefix = ""
    } else {
      prefix = String(buf[start..<pos])
      if let cmdPart = prefix.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).first {
        cmd = String(cmdPart)
      }
    }
    
    return CompleteToken(
      range: range,
      value: String(input[range]),
      
      quote: qch,
      isRedirect: isRedirect,
      
      prefix: prefix,
      query: query,
      
      cmd: cmd
    )
  }

}
