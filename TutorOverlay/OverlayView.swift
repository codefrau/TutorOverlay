//
//  OverlayView.swift
//  TutorOverlay rendering
//
//  This view is used as main view in MainMenu.xib
//
//  Created by Bert Freudenberg on 15.06.16.
//  Copyright © 2016 Bert Freudenberg. All rights reserved.
//

import Cocoa

class OverlayView: NSView {
    var display_list: [() -> Void] = []
    var my_color = NSColor.blackColor()
    
    override func drawRect(dirtyRect: NSRect)
    {
        if display_list.count > 0 {
            my_color = NSColor.blackColor()
            my_color.set()
            for closure in display_list {
                closure()
            }
        } else {
            let circleFillColor = NSColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)
            let circleRect = NSMakeRect(0, 0, dirtyRect.size.width, dirtyRect.size.height)
            let cPath: NSBezierPath = NSBezierPath(ovalInRect: circleRect)
            cPath.appendBezierPathWithOvalInRect(circleRect.insetBy(dx: 10, dy: 10))
            cPath.windingRule = NSWindingRule.EvenOddWindingRule
            circleFillColor.set()
            cPath.fill()
        }
    }
    
    // sent from TCP listener in concurrent queue
    func receive_command_in_background(string: String) -> String {
        if let range = string.rangeOfString("^\\S+", options: .RegularExpressionSearch) {
            let cmd = string.substringWithRange(range)
            let args = string.substringFromIndex(range.endIndex)
            return handle_command_in_background(cmd, args: args)
        } else {
            return "ERROR no command found"
        }
    }
 
    func handle_command_in_background(cmd: String, args argstring: String) -> String {
        switch cmd.uppercaseString {
        case "HELP":
            return "Commands:\r\nCLEAR\r\nCOLOR r g b a\r\nRECT x y w h\r\nTEXT x y h|text\r\nCoords are 0...1 fractions of full screen"
        case "CLEAR":
            return cmd_CLEAR()
        case "COLOR":
            return cmd_COLOR(parse_numbers(argstring))
        case "RECT":
            return cmd_RECT(parse_numbers(argstring))
        case "TEXT":
            return cmd_TEXT(parse_numbers(argstring), string: parse_text(argstring))
        default:
            return "ERROR unknown command, try HELP"
        }
    }
    
    func parse_text(string: String) -> String {
        // texts starts at | ...
        if let bar = string.rangeOfString("\\|\\s*", options: .RegularExpressionSearch) {
            let start = bar.endIndex
            var end = string.endIndex
            // ... and ends at the trailing whitespace
            if let whitespace = string.rangeOfString("\\s*$", options: .RegularExpressionSearch) {
                end = whitespace.startIndex
            }
            return string.substringWithRange(start..<end)
        } else {
            return ""
        }
    }

    func parse_numbers(string: String) -> [CGFloat] {
        let strings = string.componentsSeparatedByString(" ")
        var numbers: [CGFloat] = []
        for string in strings {
            if let range = string.rangeOfString("^\\S+", options: .RegularExpressionSearch) {
                let clean = string.substringWithRange(range)
                if let number = Double(clean) {
                    numbers.append(CGFloat(number))
                }
            }
        }
        return numbers
    }

    func display_list_append(closure: () -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            self.display_list.append(closure)
            self.needsDisplay = true
        }
    }

    func cmd_CLEAR() -> String {
        dispatch_async(dispatch_get_main_queue()) {
            self.display_list = [{}]    // one element to hide big oval
            self.needsDisplay = true
        }
        return "OK"
    }
    
    func cmd_COLOR(args: [CGFloat]) -> String {
        if args.count != 4 { return "ERROR COLOR red green blue alpha" }
        display_list_append {
            self.my_color = NSColor(red: args[0], green: args[1], blue: args[2], alpha: args[3])
            self.my_color.set()
        }
        return "OK"
    }

    func cmd_RECT(args: [CGFloat]) -> String {
        if args.count != 4 { return "ERROR RECT x y w h" }
        display_list_append {
            let w = self.frame.width, h = self.frame.height
            let rect = NSMakeRect(args[0] * w, args[1] * h, args[2] * w, args[3] * h)
            let path: NSBezierPath = NSBezierPath(rect: rect)
            path.fill()
        }
        return "OK"
    }

    func cmd_TEXT(args: [CGFloat], string: String) -> String {
        if args.count != 3 { return "ERROR TEXT x y h | text" }
        display_list_append {
            let w = self.frame.width, h = self.frame.height
            let attrString = NSAttributedString(string: string,
                attributes: [NSFontAttributeName: NSFont(name: "Helvetica", size: args[2] * h)!, NSForegroundColorAttributeName: self.my_color])
            attrString.drawAtPoint(NSPoint(x: args[0] * w, y: args[1] * h))
        }
        return "OK"
    }

}