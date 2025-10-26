import CloudKit

func ckExplain(_ error: Error) -> String {
    guard let ckError = error as? CKError else {
        return error.localizedDescription
    }

    var parts = ["CKError.\(ckError.code.rawValue) (\(ckError.code))"]

    if ckError.code == .partialFailure,
       let partials = ckError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] {
        let mapped = partials.map { itemID, error -> String in
            let code = (error as? CKError)?.code ?? .unknownItem
            return "\(itemID): \(code)"
        }
        if !mapped.isEmpty {
            parts.append(mapped.joined(separator: ", "))
        }
    }

    return parts.joined(separator: " | ")
}
