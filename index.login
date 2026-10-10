
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CampusCare | Login & Verification</title>
  <link rel="stylesheet" href="login.css">
</head>
<body>
  <header>
    <a class="logo" href="index.html">CampusCare.</a>
    <a class="back-link" href="index.html">← Back to Home</a>
  </header>

  <main class="auth-card">
    <h1>Welcome to CampusCare</h1>
    <p class="subtitle">Sign in or create your student account.</p>

    <div class="tabs">
      <button type="button" id="signupTab" class="tab active">
        Create Account
      </button>
      <button type="button" id="loginTab" class="tab">
        Log In
      </button>
    </div>

    <form id="signupForm">
      <label for="name">Full Name</label>
      <input id="name" type="text" autocomplete="name"
             maxlength="100" required placeholder="Enter your full name">

      <label for="phone">Phone Number</label>
      <input id="phone" type="tel" autocomplete="tel"
             required placeholder="+8801XXXXXXXXX">

      <label for="password">Create Password</label>
      <input id="password" type="password" minlength="8"
             autocomplete="new-password" required
             placeholder="At least 8 characters">

      <button class="main-btn" type="submit">Sign Up & Send OTP</button>
    </form>

    <form id="loginForm" hidden>
      <label for="loginPhone">Phone Number</label>
      <input id="loginPhone" type="tel" autocomplete="tel"
             required placeholder="+8801XXXXXXXXX">

      <label for="loginPassword">Password</label>
      <input id="loginPassword" type="password"
             autocomplete="current-password" required
             placeholder="Enter your password">

      <button class="main-btn" type="submit">Log In</button>
    </form>

    <form id="otpForm" hidden>
      <h2>Verify Your Phone</h2>
      <p>Enter the verification code sent to your phone by SMS.</p>

      <label for="otp">6-Digit OTP</label>
      <input id="otp" type="text" inputmode="numeric"
             autocomplete="one-time-code" pattern="[0-9]{6}"
             maxlength="6" required placeholder="123456">

      <button class="main-btn" type="submit">Verify Account</button>
      <button class="text-btn" id="backToSignup" type="button">
        Back to signup
      </button>
    </form>

    <p id="message" role="status" aria-live="polite"></p>
    <a class="home-link" href="index.html">Return to homepage</a>
  </main>

  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <script>
    // Replace these two values with your own Supabase project details.
    const SUPABASE_URL = "https://YOUR_PROJECT_ID.supabase.co";
    const SUPABASE_PUBLISHABLE_KEY = "YOUR_PUBLISHABLE_KEY";

    const supabaseClient = window.supabase.createClient(
      SUPABASE_URL,
      SUPABASE_PUBLISHABLE_KEY
    );

    const $ = id => document.getElementById(id);
    let pendingPhone = "";

    function showMessage(text, success = false) {
      $("message").textContent = text;
      $("message").className = success ? "success" : "error";
    }

    function validPhone(phone) {
      return /^\+[1-9]\d{7,14}$/.test(phone);
    }

    $("signupTab").addEventListener("click", () => {
      $("signupForm").hidden = false;
      $("loginForm").hidden = true;
      $("otpForm").hidden = true;
      $("signupTab").classList.add("active");
      $("loginTab").classList.remove("active");
      showMessage("");
    });

    $("loginTab").addEventListener("click", () => {
      $("signupForm").hidden = true;
      $("loginForm").hidden = false;
      $("otpForm").hidden = true;
      $("loginTab").classList.add("active");
      $("signupTab").classList.remove("active");
      showMessage("");
    });

    $("signupForm").addEventListener("submit", async event => {
      event.preventDefault();

      const name = $("name").value.trim();
      const phone = $("phone").value.trim();
      const password = $("password").value;

      if (!validPhone(phone)) {
        return showMessage(
          "Enter a valid international number, e.g. +8801XXXXXXXXX."
        );
      }

      if (name.length < 2 || password.length < 8) {
        return showMessage(
          "Enter your full name and a password of at least 8 characters."
        );
      }

      const button = $("signupForm").querySelector("button[type=submit]");
      button.disabled = true;

      try {
        const { data, error } = await supabaseClient.auth.signUp({
          phone,
          password,
          options: {
            data: { full_name: name },
            channel: "sms"
          }
        });

        if (error) throw error;

        if (data.session) {
          showMessage(
            "Your account was created and you are signed in.",
            true
          );
          $("signupForm").hidden = true;
          return;
        }

        pendingPhone = phone;
        $("signupForm").hidden = true;
        $("loginForm").hidden = true;
        $("otpForm").hidden = false;
        showMessage("Signup submitted. Enter the SMS code to verify.");
      } catch (error) {
        showMessage(error.message || "Signup failed. Please try again.");
      } finally {
        button.disabled = false;
      }
    });

    $("otpForm").addEventListener("submit", async event => {
      event.preventDefault();

      const token = $("otp").value.trim();

      if (!pendingPhone || !/^\d{6}$/.test(token)) {
        return showMessage("Enter the six-digit OTP.");
      }

      const button = $("otpForm").querySelector("button[type=submit]");
      button.disabled = true;

      try {
        const { error } = await supabaseClient.auth.verifyOtp({
          phone: pendingPhone,
          token,
          type: "sms"
        });

        if (error) throw error;

        pendingPhone = "";
        showMessage("Phone verified successfully! You can now use CampusCare.", true);
        $("otpForm").hidden = true;
        $("loginForm").hidden = false;
        $("loginTab").classList.add("active");
        $("signupTab").classList.remove("active");
      } catch (error) {
        showMessage(error.message || "OTP verification failed.");
      } finally {
        button.disabled = false;
      }
    });

    $("loginForm").addEventListener("submit", async event => {
      event.preventDefault();

      const phone = $("loginPhone").value.trim();
      const password = $("loginPassword").value;

      if (!validPhone(phone)) {
        return showMessage("Enter a valid international phone number.");
      }

      const button = $("loginForm").querySelector("button[type=submit]");
      button.disabled = true;

      try {
        const { data, error } =
          await supabaseClient.auth.signInWithPassword({
            phone,
            password
          });

        if (error) throw error;

        showMessage("Login successful! Welcome to CampusCare.", true);

        // Redirect to a protected student page when you create one.
        // window.location.href = "dashboard.html";
      } catch (error) {
        showMessage(error.message || "Login failed.");
      } finally {
        button.disabled = false;
      }
    });

    $("backToSignup").addEventListener("click", () => {
      $("otpForm").hidden = true;
      $("signupForm").hidden = false;
      $("signupTab").classList.add("active");
      $("loginTab").classList.remove("active");
      showMessage("");
    });
  </script>
</body>
</html>
