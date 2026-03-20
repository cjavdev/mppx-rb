# frozen_string_literal: true

RSpec.describe Mppx::Errors do
  def error_snapshot(error)
    {
      name: error.class.name.split("::").last,
      message: error.message,
      type: error.type,
      status: error.status
    }
  end

  describe Mppx::Errors::MalformedCredentialError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "MalformedCredentialError",
        message: "Credential is malformed.",
        status: 402,
        type: "https://paymentauth.org/problems/malformed-credential"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "invalid base64url"))).to eq(
        name: "MalformedCredentialError",
        message: "Credential is malformed: invalid base64url.",
        status: 402,
        type: "https://paymentauth.org/problems/malformed-credential"
      )
    end
  end

  describe Mppx::Errors::InvalidChallengeError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "InvalidChallengeError",
        message: "Challenge is invalid.",
        status: 402,
        type: "https://paymentauth.org/problems/invalid-challenge"
      )
    end

    it "with id" do
      expect(error_snapshot(described_class.new(id: "abc123"))).to eq(
        name: "InvalidChallengeError",
        message: 'Challenge "abc123" is invalid.',
        status: 402,
        type: "https://paymentauth.org/problems/invalid-challenge"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "expired"))).to eq(
        name: "InvalidChallengeError",
        message: "Challenge is invalid: expired.",
        status: 402,
        type: "https://paymentauth.org/problems/invalid-challenge"
      )
    end

    it "with id and reason" do
      expect(error_snapshot(described_class.new(id: "abc123", reason: "already used"))).to eq(
        name: "InvalidChallengeError",
        message: 'Challenge "abc123" is invalid: already used.',
        status: 402,
        type: "https://paymentauth.org/problems/invalid-challenge"
      )
    end
  end

  describe Mppx::Errors::VerificationFailedError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "VerificationFailedError",
        message: "Payment verification failed.",
        status: 402,
        type: "https://paymentauth.org/problems/verification-failed"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "invalid signature"))).to eq(
        name: "VerificationFailedError",
        message: "Payment verification failed: invalid signature.",
        status: 402,
        type: "https://paymentauth.org/problems/verification-failed"
      )
    end
  end

  describe Mppx::Errors::PaymentActionRequiredError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "PaymentActionRequiredError",
        message: "Payment requires action.",
        status: 402,
        type: "https://paymentauth.org/problems/payment-action-required"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "requires_action"))).to eq(
        name: "PaymentActionRequiredError",
        message: "Payment requires action: requires_action.",
        status: 402,
        type: "https://paymentauth.org/problems/payment-action-required"
      )
    end

    it "toProblemDetails with challengeId" do
      error = described_class.new(reason: "Stripe PaymentIntent requires action")
      expect(error.to_problem_details("ch_123")).to eq(
        type: "https://paymentauth.org/problems/payment-action-required",
        title: "Payment Action Required",
        status: 402,
        detail: "Payment requires action: Stripe PaymentIntent requires action.",
        challengeId: "ch_123"
      )
    end
  end

  describe Mppx::Errors::PaymentExpiredError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "PaymentExpiredError",
        message: "Payment has expired.",
        status: 402,
        type: "https://paymentauth.org/problems/payment-expired"
      )
    end

    it "with expires" do
      expect(error_snapshot(described_class.new(expires: "2025-01-26T12:00:00Z"))).to eq(
        name: "PaymentExpiredError",
        message: "Payment expired at 2025-01-26T12:00:00Z.",
        status: 402,
        type: "https://paymentauth.org/problems/payment-expired"
      )
    end
  end

  describe Mppx::Errors::PaymentRequiredError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "PaymentRequiredError",
        message: "Payment is required.",
        status: 402,
        type: "https://paymentauth.org/problems/payment-required"
      )
    end

    it "with description" do
      expect(error_snapshot(described_class.new(description: "API access fee"))).to eq(
        name: "PaymentRequiredError",
        message: "Payment is required (API access fee).",
        status: 402,
        type: "https://paymentauth.org/problems/payment-required"
      )
    end
  end

  describe Mppx::Errors::InvalidPayloadError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "InvalidPayloadError",
        message: "Credential payload is invalid.",
        status: 402,
        type: "https://paymentauth.org/problems/invalid-payload"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "missing signature field"))).to eq(
        name: "InvalidPayloadError",
        message: "Credential payload is invalid: missing signature field.",
        status: 402,
        type: "https://paymentauth.org/problems/invalid-payload"
      )
    end
  end

  describe Mppx::Errors::BadRequestError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "BadRequestError",
        message: "Bad request.",
        status: 400,
        type: "https://paymentauth.org/problems/bad-request"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "cannot combine hash type with feePayer"))).to eq(
        name: "BadRequestError",
        message: "Bad request: cannot combine hash type with feePayer.",
        status: 400,
        type: "https://paymentauth.org/problems/bad-request"
      )
    end
  end

  describe Mppx::Errors::PaymentInsufficientError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "PaymentInsufficientError",
        message: "Payment amount is insufficient.",
        status: 402,
        type: "https://paymentauth.org/problems/payment-insufficient"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "expected 1000, received 500"))).to eq(
        name: "PaymentInsufficientError",
        message: "Payment insufficient: expected 1000, received 500.",
        status: 402,
        type: "https://paymentauth.org/problems/payment-insufficient"
      )
    end
  end

  describe Mppx::Errors::PaymentMethodUnsupportedError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "PaymentMethodUnsupportedError",
        message: "Payment method is not supported.",
        status: 400,
        type: "https://paymentauth.org/problems/method-unsupported"
      )
    end

    it "with method" do
      expect(error_snapshot(described_class.new(method: "bitcoin"))).to eq(
        name: "PaymentMethodUnsupportedError",
        message: 'Payment method "bitcoin" is not supported.',
        status: 400,
        type: "https://paymentauth.org/problems/method-unsupported"
      )
    end
  end

  describe Mppx::Errors::InsufficientBalanceError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "InsufficientBalanceError",
        message: "Insufficient balance.",
        status: 402,
        type: "https://paymentauth.org/problems/session/insufficient-balance"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "requested 500, available 100"))).to eq(
        name: "InsufficientBalanceError",
        message: "Insufficient balance: requested 500, available 100.",
        status: 402,
        type: "https://paymentauth.org/problems/session/insufficient-balance"
      )
    end
  end

  describe Mppx::Errors::InvalidSignatureError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "InvalidSignatureError",
        message: "Invalid signature.",
        status: 402,
        type: "https://paymentauth.org/problems/session/invalid-signature"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "ECDSA recovery failed"))).to eq(
        name: "InvalidSignatureError",
        message: "Invalid signature: ECDSA recovery failed.",
        status: 402,
        type: "https://paymentauth.org/problems/session/invalid-signature"
      )
    end
  end

  describe Mppx::Errors::SignerMismatchError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "SignerMismatchError",
        message: "Signer is not authorized for this channel.",
        status: 402,
        type: "https://paymentauth.org/problems/session/signer-mismatch"
      )
    end
  end

  describe Mppx::Errors::AmountExceedsDepositError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "AmountExceedsDepositError",
        message: "Voucher amount exceeds channel deposit.",
        status: 402,
        type: "https://paymentauth.org/problems/session/amount-exceeds-deposit"
      )
    end
  end

  describe Mppx::Errors::DeltaTooSmallError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "DeltaTooSmallError",
        message: "Amount increase below minimum voucher delta.",
        status: 402,
        type: "https://paymentauth.org/problems/session/delta-too-small"
      )
    end
  end

  describe Mppx::Errors::ChannelNotFoundError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "ChannelNotFoundError",
        message: "No channel with this ID exists.",
        status: 410,
        type: "https://paymentauth.org/problems/session/channel-not-found"
      )
    end
  end

  describe Mppx::Errors::ChannelClosedError do
    it "default" do
      expect(error_snapshot(described_class.new)).to eq(
        name: "ChannelClosedError",
        message: "Channel is closed.",
        status: 410,
        type: "https://paymentauth.org/problems/session/channel-finalized"
      )
    end

    it "with reason" do
      expect(error_snapshot(described_class.new(reason: "channel is finalized on-chain"))).to eq(
        name: "ChannelClosedError",
        message: "Channel closed: channel is finalized on-chain.",
        status: 410,
        type: "https://paymentauth.org/problems/session/channel-finalized"
      )
    end
  end

  describe "toProblemDetails" do
    it "without challengeId" do
      error = Mppx::Errors::MalformedCredentialError.new(reason: "invalid JSON")
      expect(error.to_problem_details).to eq(
        type: "https://paymentauth.org/problems/malformed-credential",
        title: "Malformed Credential",
        status: 402,
        detail: "Credential is malformed: invalid JSON."
      )
    end

    it "with challengeId" do
      error = Mppx::Errors::InvalidChallengeError.new(id: "abc123", reason: "expired")
      expect(error.to_problem_details("abc123")).to eq(
        type: "https://paymentauth.org/problems/invalid-challenge",
        title: "Invalid Challenge",
        status: 402,
        detail: 'Challenge "abc123" is invalid: expired.',
        challengeId: "abc123"
      )
    end
  end
end
