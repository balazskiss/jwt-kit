import Core
import Foundation

extension JSON {

    public func makeBytes2() throws -> Bytes {
        return try serialize2()
    }

    public func serialize2(prettyPrint: Bool = false) throws -> Bytes {
        switch wrapped {
        case .array, .object:
            return try _nsSerialize2(prettyPrint: prettyPrint)
        case .bool(let b):
            return b ? [.t, .r, .u, .e] : [.f, .a, .l, .s, .e]
        case .bytes(let b):
            let encoded = b.base64Encoded
            return [.quote] + encoded + [.quote]
        case .date, .string:
            let bytes = string?.escaped().makeBytes() ?? []
            return [.quote] + bytes + [.quote]
        case .number:
            return string?.makeBytes() ?? []
        case .null:
            return [.n, .u, .l, .l]
        }
    }

    private func _nsSerialize2(prettyPrint: Bool) throws -> Bytes {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrint {
            options.insert(.prettyPrinted)
        }
        if #available(OSX 10.13, *) {
            options.insert(.sortedKeys)
        }
        #if os(Linux)
            options.insert(.sortedKeys)
        #endif

        let data = try JSONSerialization.data(
            withJSONObject: wrapped.foundationJSON,
            options: options
        )
        return data.makeBytes()
    }

}

extension String {
    fileprivate func escaped() -> String {
        var string = ""
        string.reserveCapacity(string.toCharacterSequence().count)

        for char in self.toCharacterSequence() {
            switch char {
            case "\"":
                string += "\\\""
            case "\\":
                string += "\\\\"
            case "\t":
                string += "\\t"
            case "\n":
                string += "\\n"
            case "\r":
                string += "\\r"
            default:
                string.append(char)
            }
        }

        return string
    }
}

extension String {
    #if swift(>=4.0)
    internal func toCharacterSequence() -> String {
        return self
    }
    #else
    internal func toCharacterSequence() -> CharacterView {
        return self.characters
    }
    #endif
}

extension StructuredData {
    var foundationJSON: Any {
        switch self {
        case .array(let values):
            return values.map { $0.foundationJSON }
        case .bool(let value):
            return value
        case .bytes(let bytes):
            return bytes.base64Encoded.makeString()
        case .null:
            return NSNull()
        case .number(let number):
            switch number {
            case .double(let value):
                return value
            case .int(let value):
                return value
            case .uint(let value):
                return value
            }
        case .object(let values):
            var dictionary: [String: Any] = [:]
            for (key, value) in values {
                dictionary[key] = value.foundationJSON
            }
            return dictionary
        case .string(let value):
            return value
        case .date(let date):
            let string = Date.outgoingDateFormatter.string(from: date)
            return string
        }
    }
}
