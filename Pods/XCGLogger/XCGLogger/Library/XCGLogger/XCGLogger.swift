//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

// MARK: - XCGLogDetails
// - Data structure to hold all info about a log message, passed to log destination classes
public struct XCGLogDetails {
    public var logLevel: XCGLogger.LogLevel
    public var date: NSDate
    public var logMessage: String
    public var functionName: String
    public var fileName: String
    public var lineNumber: Int

    public init(logLevel: XCGLogger.LogLevel, date: NSDate, logMessage: String, functionName: String, fileName: String, lineNumber: Int) {
        self.logLevel = logLevel
        self.date = date
        self.logMessage = logMessage
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
    }
}

// MARK: - XCGLogDestinationProtocol
// - Protocol for output classes to conform to
public protocol XCGLogDestinationProtocol: DebugPrintable {
    var owner: XCGLogger {get set}
    var identifier: String {get set}
    var outputLogLevel: XCGLogger.LogLevel {get set}

    func processLogDetails(logDetails: XCGLogDetails)
    func processInternalLogDetails(logDetails: XCGLogDetails) // Same as processLogDetails but should omit function/file/line info
    func isEnabledForLogLevel(logLevel: XCGLogger.LogLevel) -> Bool
}

// MARK: - XCGBaseLogDestination
// - A base class log destination that doesn't actually output the log anywhere and is intented to be subclassed
public class XCGBaseLogDestination: XCGLogDestinationProtocol, DebugPrintable {
    // MARK: - Properties
    public var owner: XCGLogger
    public var identifier: String
    public var outputLogLevel: XCGLogger.LogLevel = .Debug

    public var showLogIdentifier: Bool = false
    public var showFunctionName: Bool = true
    public var showThreadName: Bool = false
    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showLogLevel: Bool = true
    public var showDate: Bool = true

    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            return "\(reflect(self.dynamicType).summary): \(identifier) - LogLevel: \(outputLogLevel) showLogIdentifier: \(showLogIdentifier) showFunctionName: \(showFunctionName) showThreadName: \(showThreadName) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber) showDate: \(showDate)"
        }
    }

    // MARK: - Life Cycle
    public init(owner: XCGLogger, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier
    }

    // MARK: - Methods to Process Log Details
    public func processLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.stringFromDate(logDetails.date)
            }

            extendedDetails += "\(formattedDate) "
        }

        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }

        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }

        if showThreadName {
            extendedDetails += "[" + (NSThread.isMainThread() ? "main" : (NSThread.currentThread().name != "" ? NSThread.currentThread().name : String(format:"%p", NSThread.currentThread()))) + "] "
        }

        if showFileName {
            extendedDetails += "[" + logDetails.fileName.lastPathComponent + (showLineNumber ? ":" + String(logDetails.lineNumber) : "") + "] "
        }
        else if showLineNumber {
            extendedDetails += "[" + String(logDetails.lineNumber) + "] "
        }

        if showFunctionName {
            extendedDetails += "\(logDetails.functionName) "
        }

        output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)")
    }

    public func processInternalLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.stringFromDate(logDetails.date)
            }

            extendedDetails += "\(formattedDate) "
        }

        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }

        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }

        output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)")
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    // MARK: - Methods that must be overriden in subclasses
    public func output(logDetails: XCGLogDetails, text: String) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
}

// MARK: - XCGConsoleLogDestination
// - A standard log destination that outputs log details to the console
public class XCGConsoleLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    // MARK: - Misc Methods
    public override func output(logDetails: XCGLogDetails, text: String) {
        let adjustedText: String
        if let xcodeColor = (xcodeColors ?? owner.xcodeColors)[logDetails.logLevel] where owner.xcodeColorsEnabled {
            adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
        }
        else {
            adjustedText = text
        }

        dispatch_async(XCGLogger.logQueue) {
            print("\(adjustedText)\n")
        }
    }
}

// MARK: - XCGNSLogDestination
// - A standard log destination that outputs log details to the console using NSLog instead of println
public class XCGNSLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    public override var showDate: Bool {
        get {
            return false
        }
        set {
            // ignored, NSLog adds the date, so we always want showDate to be false in this subclass
        }
    }

    // MARK: - Misc Methods
    public override func output(logDetails: XCGLogDetails, text: String) {
        let adjustedText: String
        if let xcodeColor = (xcodeColors ?? owner.xcodeColors)[logDetails.logLevel] where owner.xcodeColorsEnabled {
            adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
        }
        else {
            adjustedText = text
        }

        NSLog(adjustedText)
    }
}

// MARK: - XCGFileLogDestination
// - A standard log destination that outputs log details to a file
public class XCGFileLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    private var writeToFileURL: NSURL? = nil {
        didSet {
            openFile()
        }
    }
    private var logFileHandle: NSFileHandle? = nil

    // MARK: - Life Cycle
    public init(owner: XCGLogger, writeToFile: AnyObject, identifier: String = "") {
        super.init(owner: owner, identifier: identifier)

        if writeToFile is NSString {
            writeToFileURL = NSURL.fileURLWithPath(writeToFile as! String)
        }
        else if writeToFile is NSURL {
            writeToFileURL = writeToFile as? NSURL
        }
        else {
            writeToFileURL = nil
        }

        openFile()
    }

    deinit {
        // close file stream if open
        closeFile()
    }

    // MARK: - File Handling Methods
    private func openFile() {
        if logFileHandle != nil {
            closeFile()
        }

        if let writeToFileURL = writeToFileURL,
          let path = writeToFileURL.path {

            NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
            var fileError: NSError? = nil
            logFileHandle = NSFileHandle(forWritingToURL: writeToFileURL, error: &fileError)
            if logFileHandle == nil {
                owner._logln("Attempt to open log file for writing failed: \(fileError?.localizedDescription)", logLevel: .Error)
            }
            else {
                owner.logAppDetails(selectedLogDestination: self)

                let logDetails = XCGLogDetails(logLevel: .Info, date: NSDate(), logMessage: "XCGLogger writing to log to: \(writeToFileURL)", functionName: "", fileName: "", lineNumber: 0)
                owner._logln(logDetails.logMessage, logLevel: logDetails.logLevel)
                processInternalLogDetails(logDetails)
            }
        }
    }

    private func closeFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }

    // MARK: - Misc Methods
    public override func output(logDetails: XCGLogDetails, text: String) {
        if let encodedData = "\(text)\n".dataUsingEncoding(NSUTF8StringEncoding) {
            logFileHandle?.writeData(encodedData)
        }
    }
}

// MARK: - XCGLogger
// - The main logging class
public class XCGLogger: DebugPrintable {
    // MARK: - Constants
    public struct constants {
        public static let defaultInstanceIdentifier = "com.cerebralgardens.xcglogger.defaultInstance"
        public static let baseConsoleLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console"
        public static let nslogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console.nslog"
        public static let baseFileLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.file"
        public static let nsdataFormatterCacheIdentifier = "com.cerebralgardens.xcglogger.nsdataFormatterCache"
        public static let logQueueIdentifier = "com.cerebralgardens.xcglogger.queue"
        public static let versionString = "2.3"
    }

    // MARK: - Enums
    public enum LogLevel: Int, Comparable, Printable {
        case Verbose
        case Debug
        case Info
        case Warning
        case Error
        case Severe
        case None

        public var description: String {
            switch self {
            case .Verbose:
                return "Verbose"
            case .Debug:
                return "Debug"
            case .Info:
                return "Info"
            case .Warning:
                return "Warning"
            case .Error:
                return "Error"
            case .Severe:
                return "Severe"
            case .None:
                return "None"
            }
        }
    }

    public struct XcodeColor {
        public static let escape = "\u{001b}["
        public static let resetFg = "\u{001b}[fg;"
        public static let resetBg = "\u{001b}[bg;"
        public static let reset = "\u{001b}[;"

        public var fg: (Int, Int, Int)? = nil
        public var bg: (Int, Int, Int)? = nil

        public func format() -> String {
            var format: String = ""

            if fg == nil && bg == nil {
                // neither set, return reset value
                return XcodeColor.reset
            }

            if let fg = fg {
                format += "\(XcodeColor.escape)fg\(fg.0),\(fg.1),\(fg.2);"
            }
            else {
                format += XcodeColor.resetFg
            }

            if let bg = bg {
                format += "\(XcodeColor.escape)bg\(bg.0),\(bg.1),\(bg.2);"
            }
            else {
                format += XcodeColor.resetBg
            }

            return format
        }

        public init(fg: (Int, Int, Int)? = nil, bg: (Int, Int, Int)? = nil) {
            self.fg = fg
            self.bg = bg
        }

#if os(iOS)
        public init(fg: UIColor, bg: UIColor? = nil) {
            var redComponent: CGFloat = 0
            var greenComponent: CGFloat = 0
            var blueComponent: CGFloat = 0
            var alphaComponent: CGFloat = 0

            fg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
            self.fg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            if let bg = bg {
                bg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
                self.bg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#else
        public init(fg: NSColor, bg: NSColor? = nil) {
            if let fgColorSpaceCorrected = fg.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) {
                self.fg = (Int(fgColorSpaceCorrected.redComponent * 255), Int(fgColorSpaceCorrected.greenComponent * 255), Int(fgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.fg = nil
            }

            if let bg = bg,
                let bgColorSpaceCorrected = bg.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) {

                    self.bg = (Int(bgColorSpaceCorrected.redComponent * 255), Int(bgColorSpaceCorrected.greenComponent * 255), Int(bgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#endif

        public static let red: XcodeColor = {
            return XcodeColor(fg: (255, 0, 0))
        }()

        public static let green: XcodeColor = {
            return XcodeColor(fg: (0, 255, 0))
        }()

        public static let blue: XcodeColor = {
            return XcodeColor(fg: (0, 0, 255))
        }()

        public static let black: XcodeColor = {
            return XcodeColor(fg: (0, 0, 0))
        }()

        public static let white: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255))
        }()

        public static let lightGrey: XcodeColor = {
            return XcodeColor(fg: (211, 211, 211))
        }()

        public static let darkGrey: XcodeColor = {
            return XcodeColor(fg: (169, 169, 169))
        }()

        public static let orange: XcodeColor = {
            return XcodeColor(fg: (255, 165, 0))
        }()

        public static let whiteOnRed: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0))
        }()

        public static let darkGreen: XcodeColor = {
            return XcodeColor(fg: (0, 128, 0))
        }()
    }

    // MARK: - Properties (Options)
    public var identifier: String = ""
    public var outputLogLevel: LogLevel = .Debug {
        didSet {
            for index in 0 ..< logDestinations.count {
                logDestinations[index].outputLogLevel = outputLogLevel
            }
        }
    }

    public var xcodeColorsEnabled: Bool = false
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor] = [
        .Verbose: .lightGrey,
        .Debug: .darkGrey,
        .Info: .blue,
        .Warning: .orange,
        .Error: .red,
        .Severe: .whiteOnRed
    ]

    // MARK: - Properties
    public class var logQueue: dispatch_queue_t {
        struct Statics {
            static let logQueue = dispatch_queue_create(XCGLogger.constants.logQueueIdentifier, nil)
        }

        return Statics.logQueue
    }

    private var _dateFormatter: NSDateFormatter? = nil
    public var dateFormatter: NSDateFormatter? {
        get {
            if _dateFormatter != nil {
                return _dateFormatter
            }

            let defaultDateFormatter = NSDateFormatter()
            defaultDateFormatter.locale = NSLocale.currentLocale()
            defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            _dateFormatter = defaultDateFormatter

            return _dateFormatter
        }
        set {
            _dateFormatter = newValue
        }
    }

    public var logDestinations: Array<XCGLogDestinationProtocol> = []

    // MARK: - Life Cycle
    public init(identifier: String = "") {
        self.identifier = identifier

        // Check if XcodeColors is installed and enabled
        if let xcodeColors = NSProcessInfo.processInfo().environment["XcodeColors"] as? String {
            xcodeColorsEnabled = xcodeColors == "YES"
        }

        // Setup a standard console log destination
        addLogDestination(XCGConsoleLogDestination(owner: self, identifier: XCGLogger.constants.baseConsoleLogDestinationIdentifier))
    }

    // MARK: - Default instance
    public class func defaultInstance() -> XCGLogger {
        struct statics {
            static let instance: XCGLogger = XCGLogger(identifier: XCGLogger.constants.defaultInstanceIdentifier)
        }

        return statics.instance
    }

    // MARK: - Setup methods
    public class func setup(logLevel: LogLevel = .Debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        defaultInstance().setup(logLevel: logLevel, showLogIdentifier: showLogIdentifier, showFunctionName: showFunctionName, showThreadName: showThreadName, showLogLevel: showLogLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, showDate: showDate, writeToFile: writeToFile)
    }

    public func setup(logLevel: LogLevel = .Debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        outputLogLevel = logLevel;

        if let standardConsoleLogDestination = logDestination(XCGLogger.constants.baseConsoleLogDestinationIdentifier) as? XCGConsoleLogDestination {
            standardConsoleLogDestination.showLogIdentifier = showLogIdentifier
            standardConsoleLogDestination.showFunctionName = showFunctionName
            standardConsoleLogDestination.showThreadName = showThreadName
            standardConsoleLogDestination.showLogLevel = showLogLevel
            standardConsoleLogDestination.showFileName = showFileNames
            standardConsoleLogDestination.showLineNumber = showLineNumbers
            standardConsoleLogDestination.showDate = showDate
            standardConsoleLogDestination.outputLogLevel = logLevel
        }

        logAppDetails()

        if let writeToFile: AnyObject = writeToFile {
            // We've been passed a file to use for logging, set up a file logger
            let standardFileLogDestination: XCGFileLogDestination = XCGFileLogDestination(owner: self, writeToFile: writeToFile, identifier: XCGLogger.constants.baseFileLogDestinationIdentifier)

            standardFileLogDestination.showLogIdentifier = showLogIdentifier
            standardFileLogDestination.showFunctionName = showFunctionName
            standardFileLogDestination.showThreadName = showThreadName
            standardFileLogDestination.showLogLevel = showLogLevel
            standardFileLogDestination.showFileName = showFileNames
            standardFileLogDestination.showLineNumber = showLineNumbers
            standardFileLogDestination.showDate = showDate
            standardFileLogDestination.outputLogLevel = fileLogLevel ?? logLevel

            addLogDestination(standardFileLogDestination)
        }
    }

    // MARK: - Logging methods
    public class func logln(@autoclosure closure: () -> String?, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func logln(logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func logln(@autoclosure closure: () -> String?, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func logln(logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        let date = NSDate()

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    if let logMessage = closure() {
                        logDetails = XCGLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                    }
                    else {
                        break
                    }
                }

                logDestination.processLogDetails(logDetails!)
            }
        }
    }

    public class func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: logLevel, closure: closure)
    }

    public func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        if (!isEnabledForLogLevel(logLevel)) {
            return
        }

        closure()
    }

    public func logAppDetails(selectedLogDestination: XCGLogDestinationProtocol? = nil) {
        let date = NSDate()

        var buildString = ""
        if let infoDictionary = NSBundle.mainBundle().infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                buildString = "Version: \(CFBundleShortVersionString) "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                buildString += "Build: \(CFBundleVersion) "
            }
        }

        let processInfo: NSProcessInfo = NSProcessInfo.processInfo()
        let XCGLoggerVersionNumber = XCGLogger.constants.versionString

        let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .Info, date: date, logMessage: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
            XCGLogDetails(logLevel: .Info, date: date, logMessage: "XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel)", functionName: "", fileName: "", lineNumber: 0)]

        for logDestination in (selectedLogDestination != nil ? [selectedLogDestination!] : logDestinations) {
            for logDetail in logDetails {
                if !logDestination.isEnabledForLogLevel(.Info) {
                    continue;
                }

                logDestination.processInternalLogDetails(logDetail)
            }
        }
    }

    // MARK: - Convenience logging methods
    // MARK: * Verbose
    public class func verbose(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func verbose(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func verbose(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func verbose(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.logln(logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Debug
    public class func debug(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func debug(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func debug(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func debug(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.logln(logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Info
    public class func info(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func info(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func info(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func info(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.logln(logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Warning
    public class func warning(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func warning(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func warning(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func warning(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.logln(logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Error
    public class func error(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func error(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func error(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func error(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.logln(logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Severe
    public class func severe(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func severe(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.defaultInstance().logln(logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func severe(@autoclosure closure: () -> String?, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func severe(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, @noescape closure: () -> String?) {
        self.logln(logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: - Exec Methods
    // MARK: * Verbose
    public class func verboseExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Verbose, closure: closure)
    }

    public func verboseExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Verbose, closure: closure)
    }

    // MARK: * Debug
    public class func debugExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Debug, closure: closure)
    }

    public func debugExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Debug, closure: closure)
    }

    // MARK: * Info
    public class func infoExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Info, closure: closure)
    }

    public func infoExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Info, closure: closure)
    }

    // MARK: * Warning
    public class func warningExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Warning, closure: closure)
    }

    public func warningExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Warning, closure: closure)
    }

    // MARK: * Error
    public class func errorExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Error, closure: closure)
    }

    public func errorExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Error, closure: closure)
    }

    // MARK: * Severe
    public class func severeExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Severe, closure: closure)
    }

    public func severeExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Severe, closure: closure)
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    public func logDestination(identifier: String) -> XCGLogDestinationProtocol? {
        for logDestination in logDestinations {
            if logDestination.identifier == identifier {
                return logDestination
            }
        }

        return nil
    }

    public func addLogDestination(logDestination: XCGLogDestinationProtocol) -> Bool {
        let existingLogDestination: XCGLogDestinationProtocol? = self.logDestination(logDestination.identifier)
        if existingLogDestination != nil {
            return false
        }

        logDestinations.append(logDestination)
        return true
    }

    public func removeLogDestination(logDestination: XCGLogDestinationProtocol) {
        removeLogDestination(logDestination.identifier)
    }

    public func removeLogDestination(identifier: String) {
        logDestinations = logDestinations.filter({$0.identifier != identifier})
    }

    // MARK: - Private methods
    private func _logln(logMessage: String, logLevel: LogLevel = .Debug) {
        let date = NSDate()

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: "", fileName: "", lineNumber: 0)
                }

                logDestination.processInternalLogDetails(logDetails!)
            }
        }
    }

    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            var description: String = "\(reflect(self.dynamicType).summary): \(identifier) - logDestinations: \r"
            for logDestination in logDestinations {
                description += "\t \(logDestination.debugDescription)\r"
            }

            return description
        }
    }
}

// Implement Comparable for XCGLogger.LogLevel
public func < (lhs:XCGLogger.LogLevel, rhs:XCGLogger.LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
