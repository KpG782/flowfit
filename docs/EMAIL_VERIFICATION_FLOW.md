# Email Verification Flow Documentation

## 📋 Overview

FlowFit implements a seamless email verification flow that automatically checks verification status and guides users through the onboarding process.

## 🔄 User Flow

```
┌─────────────────┐
│  Signup Screen  │
│  (Enter Info)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create Account  │
│  (Supabase)     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Email Verification      │
│ Screen                  │
│                         │
│ • Auto-check every 5s   │
│ • Manual check button   │
│ • Resend email (60s CD) │
└────────┬────────────────┘
         │
         │ (Email verified)
         ▼
┌─────────────────┐
│  Survey Intro   │
│  Screen         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Survey Flow     │
│ (4 screens)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Dashboard     │
└─────────────────┘
```

## 🎯 Key Features

### 1. Auto-Verification Check
- Checks every **5 seconds** automatically
- Silent background checks (no UI interruption)
- Automatically navigates when verified

### 2. Manual Check
- "I've Verified My Email" button
- Shows loading state
- Provides feedback if not verified yet

### 3. Resend Email
- 60-second cooldown between resends
- Shows countdown timer
- Success/error feedback

### 4. User Experience
- Clean, modern UI
- Clear instructions
- Progress indicators
- Helpful error messages

## 🛠️ Technical Implementation

### Files Modified

1. **`lib/screens/auth/signup_screen.dart`**
   - Updated navigation logic
   - Routes to email verification if not verified
   - Routes directly to survey if already verified

2. **`lib/screens/auth/email_verification_screen.dart`**
   - Auto-check timer (5 seconds)
   - Manual verification check
   - Resend functionality with cooldown
   - Error handling

### Key Code Sections

#### Auto-Check Timer
```dart
void _startAutoCheck() {
  _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    _checkVerification(silent: true);
  });
}
```

#### Verification Check
```dart
Future<void> _checkVerification({bool silent = false}) async {
  // Refresh session and check emailConfirmedAt
  final response = await Supabase.instance.client.auth.refreshSession();
  final user = response.user;
  final isVerified = user?.emailConfirmedAt != null;
  
  if (isVerified) {
    _onVerificationSuccess();
  }
}
```

#### Navigation Logic
```dart
if (next.status == AuthStatus.authenticated && next.user != null) {
  final isEmailVerified = next.user!.emailConfirmedAt != null;
  
  if (isEmailVerified) {
    Navigator.pushReplacementNamed(context, '/survey_intro', ...);
  } else {
    Navigator.pushReplacementNamed(context, '/email_verification', ...);
  }
}
```

## 📧 Email Template

### Subject Line
```
Confirm Your FlowFit Signup ⚡
```

### Template Variables
- `{{ .ConfirmationURL }}` - Verification link
- `{{ .Email }}` - User's email
- `{{ .SiteURL }}` - App URL

### Design
- Modern, responsive HTML
- FlowFit branding
- Clear call-to-action button
- Security information
- Plain text fallback

## ⚙️ Configuration

### Supabase Settings

**Site URL:**
- Development: `http://localhost:3000`
- Production: `https://flowfit.app`

**Redirect URLs:**
```
http://localhost:3000
http://localhost:3000/auth/callback
flowfit://auth/callback
flowfit://email-verification
```

### Email Template Location
```
supabase/email_templates/
├── confirm_signup.html      # HTML email template
├── confirm_signup.txt       # Plain text fallback
├── EMAIL_SETUP_GUIDE.md     # Detailed setup guide
└── QUICK_SETUP.md           # Quick reference
```

## 🧪 Testing

### Test Scenarios

1. **Happy Path**
   - Sign up → Receive email → Click link → Auto-navigate to survey

2. **Manual Check**
   - Sign up → Click "I've Verified" before verifying → See error
   - Verify email → Click "I've Verified" → Navigate to survey

3. **Resend Email**
   - Sign up → Click "Resend" → Wait 60s → Can resend again

4. **Auto-Detection**
   - Sign up → Wait on screen → Verify in another tab → Auto-navigate

### Testing Checklist
- [ ] Email received in inbox
- [ ] Email not in spam
- [ ] Verification link works
- [ ] Auto-check detects verification
- [ ] Manual check works
- [ ] Resend has cooldown
- [ ] Navigation to survey works
- [ ] User data passed correctly

## 🚀 Production Deployment

### Pre-Launch Checklist
- [ ] Update Site URL to production domain
- [ ] Add production redirect URLs
- [ ] Test email delivery
- [ ] Verify deep links work on mobile
- [ ] Remove "Skip for now" button
- [ ] Test end-to-end flow
- [ ] Monitor email delivery rates
- [ ] Set up email analytics

### Environment Variables
```dart
// In production, ensure these are set:
SUPABASE_URL=your_production_url
SUPABASE_ANON_KEY=your_production_key
```

## 📊 Monitoring

### Metrics to Track
- Email delivery rate
- Verification completion rate
- Time to verification
- Resend frequency
- Drop-off points

### Error Scenarios
- Email not delivered
- Link expired
- Network errors
- Session timeout

## 🔒 Security

### Best Practices
- Email verification required before full access
- Secure token generation
- HTTPS for all links
- Rate limiting on resend
- Session validation

### Privacy
- No PII in email subject
- Secure link expiration
- Clear privacy policy link
- Opt-out instructions

## 📱 Mobile Deep Linking

### Android Configuration
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="flowfit" android:host="auth" />
</intent-filter>
```

### iOS Configuration
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>flowfit</string>
        </array>
    </dict>
</array>
```

## 🐛 Troubleshooting

### Common Issues

**Email not received:**
- Check spam folder
- Verify SMTP settings
- Check email template is enabled

**Link not working:**
- Verify redirect URLs
- Check Site URL configuration
- Test deep link setup

**Auto-check not working:**
- Verify timer is running
- Check network connectivity
- Ensure session is valid

## 📚 Related Documentation

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Templates Guide](../supabase/email_templates/EMAIL_SETUP_GUIDE.md)
- [Quick Setup](../supabase/email_templates/QUICK_SETUP.md)
- [Survey Flow](./SURVEY_FLOW.md)

## 🎨 UI/UX Considerations

### Design Principles
- **Clear Communication**: Users know exactly what to do
- **Automatic Progress**: No manual refresh needed
- **Helpful Feedback**: Clear error messages
- **Easy Recovery**: Simple resend process
- **Professional Look**: Matches app branding

### Accessibility
- High contrast colors
- Clear button labels
- Screen reader support
- Keyboard navigation
- Error announcements

## 📝 Future Enhancements

### Potential Improvements
- [ ] SMS verification option
- [ ] Social auth integration
- [ ] Magic link login
- [ ] Biometric verification
- [ ] Progressive onboarding
- [ ] Email preview in app
- [ ] Verification analytics dashboard

## 🤝 Support

For issues or questions:
- Check troubleshooting section
- Review setup guides
- Contact: support@flowfit.app
