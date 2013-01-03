module WashOut
  class Wsse

    def self.authenticate(token)
      wsse = self.new(token)

      unless wsse.eligible?
        raise WashOut::Dispatcher::SOAPError, "Unauthorized"
      end
    end

    def initialize(token)
      if token.blank? && required?
        raise WashOut::Dispatcher::SOAPError, "Missing required UsernameToken"
      end
      @username_token = token
    end

    def required?
      !WashOut::Engine.wsse_username.blank?
    end

    def expected_user
      WashOut::Engine.wsse_username
    end

    def expected_password
      WashOut::Engine.wsse_password
    end

    def matches_expected_digest?(password)
      nonce     = @username_token.values_at(:nonce, :Nonce).compact.first
      timestamp = @username_token.values_at(:created, :Created).compact.first

      return false if nonce.nil? || timestamp.nil?

      # Token should not be accepted if timestamp is older than 5 minutes ago
      # http://www.oasis-open.org/committees/download.php/16782/wss-v1.1-spec-os-UsernameTokenProfile.pdf
      offset_in_minutes = ((DateTime.now - timestamp)* 24 * 60).to_i
      return false if offset_in_minutes >= 5

      # There are a few different implementations of the digest calculation

      flavors = Array.new

      # Ruby / Savon
      token = nonce + timestamp.to_s + expected_password
      flavors << Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!

      # Java
      token = Base64.decode64(nonce) + timestamp.to_s + expected_password
      flavors << Base64.encode64(Digest::SHA1.digest(token)).chomp!

      flavors.each do |f|
        return true if f == password
      end

      return false
    end

    def eligible?
      return true unless required?

      user     = @username_token.values_at(:username, :Username).compact.first
      password = @username_token.values_at(:password, :Password).compact.first

      if (expected_user == user && expected_password == password)
        return true
      end

      if (expected_user == user && matches_expected_digest?(password))
        return true
      end

      return false
    end

  end
end
