# frozen_string_literal: true

module Mppx
  module Errors
    class PaymentError < StandardError
      def type
        raise NotImplementedError
      end

      def title
        raise NotImplementedError
      end

      def status
        402
      end

      def to_problem_details(challenge_id = nil)
        result = {
          type: type,
          title: title,
          status: status,
          detail: message
        }
        result[:challengeId] = challenge_id if challenge_id
        result
      end
    end

    class MalformedCredentialError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Credential is malformed: #{reason}." : "Credential is malformed."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/malformed-credential"
      def title = "Malformed Credential"
      def status = 402
    end

    class InvalidChallengeError < PaymentError
      def initialize(id: nil, reason: nil)
        id_part = id ? " \"#{id}\"" : ""
        reason_part = reason ? ": #{reason}" : ""
        super("Challenge#{id_part} is invalid#{reason_part}.")
      end

      def type = "https://paymentauth.org/problems/invalid-challenge"
      def title = "Invalid Challenge"
      def status = 402
    end

    class VerificationFailedError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Payment verification failed: #{reason}." : "Payment verification failed."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/verification-failed"
      def title = "Verification Failed"
      def status = 402
    end

    class PaymentActionRequiredError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Payment requires action: #{reason}." : "Payment requires action."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/payment-action-required"
      def title = "Payment Action Required"
      def status = 402
    end

    class PaymentExpiredError < PaymentError
      def initialize(expires: nil)
        msg = expires ? "Payment expired at #{expires}." : "Payment has expired."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/payment-expired"
      def title = "Payment Expired"
      def status = 402
    end

    class PaymentRequiredError < PaymentError
      def initialize(description: nil)
        parts = ["Payment is required"]
        parts << "(#{description})" if description
        super("#{parts.join(" ")}.")
      end

      def type = "https://paymentauth.org/problems/payment-required"
      def title = "Payment Required"
      def status = 402
    end

    class InvalidPayloadError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Credential payload is invalid: #{reason}." : "Credential payload is invalid."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/invalid-payload"
      def title = "Invalid Payload"
      def status = 402
    end

    class BadRequestError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Bad request: #{reason}." : "Bad request."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/bad-request"
      def title = "Bad Request"
      def status = 400
    end

    class PaymentInsufficientError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Payment insufficient: #{reason}." : "Payment amount is insufficient."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/payment-insufficient"
      def title = "Payment Insufficient"
      def status = 402
    end

    class PaymentMethodUnsupportedError < PaymentError
      def initialize(method: nil)
        msg = method ? "Payment method \"#{method}\" is not supported." : "Payment method is not supported."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/method-unsupported"
      def title = "Method Unsupported"
      def status = 400
    end

    class InsufficientBalanceError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Insufficient balance: #{reason}." : "Insufficient balance."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/session/insufficient-balance"
      def title = "Insufficient Balance"
      def status = 402
    end

    class InvalidSignatureError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Invalid signature: #{reason}." : "Invalid signature."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/session/invalid-signature"
      def title = "Invalid Signature"
      def status = 402
    end

    class SignerMismatchError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Signer mismatch: #{reason}." : "Signer is not authorized for this channel."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/session/signer-mismatch"
      def title = "Signer Mismatch"
      def status = 402
    end

    class AmountExceedsDepositError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Amount exceeds deposit: #{reason}." : "Voucher amount exceeds channel deposit."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/session/amount-exceeds-deposit"
      def title = "Amount Exceeds Deposit"
      def status = 402
    end

    class DeltaTooSmallError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Delta too small: #{reason}." : "Amount increase below minimum voucher delta."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/session/delta-too-small"
      def title = "Delta Too Small"
      def status = 402
    end

    class ChannelNotFoundError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Channel not found: #{reason}." : "No channel with this ID exists."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/session/channel-not-found"
      def title = "Channel Not Found"
      def status = 410
    end

    class ChannelClosedError < PaymentError
      def initialize(reason: nil)
        msg = reason ? "Channel closed: #{reason}." : "Channel is closed."
        super(msg)
      end

      def type = "https://paymentauth.org/problems/session/channel-finalized"
      def title = "Channel Closed"
      def status = 410
    end
  end
end
