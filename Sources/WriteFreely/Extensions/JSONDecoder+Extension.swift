// Credit: https://github.com/vapor/vapor/issues/2481#issuecomment-702013846

import Foundation

extension JSONDecoder.DateDecodingStrategy {

    /// The strategy that formats dates according to the ISO 8601 standard.
    /// - Note: This includes the fractional seconds, unlike the standard `.iso8601`, which fails to decode those.
    static var iso8601WithPossibleFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        JSONDecoder.DateDecodingStrategy.custom { (decoder) in
            let singleValue = try decoder.singleValueContainer()
            let dateString  = try singleValue.decode(String.self)

            let formatter = ISO8601DateFormatter()

            /// Use the `.withFractionalSeconds` option only if we have fractional seconds in the date string.
            if dateString.contains(".") {
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            } else {
                formatter.formatOptions = [.withInternetDateTime]
            }

            guard let date = formatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    in: singleValue,
                    debugDescription: "Failed to decode string to ISO 8601 date."
                )
            }
            return date
        }
    }

}
