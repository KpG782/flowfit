# Email Verification Setup Checklist

Use this checklist to ensure everything is configured correctly.

## ✅ Code Changes (Already Done)

- [x] AndroidManifest.xml updated with deep link intent filter
- [x] main.dart updated with PKCE flow and deep link handler
- [x] DeepLinkHandler utility created
- [x] AuthRepository updated with `emailRedirectTo` parameter

## 📋 Supabase Dashboard Configuration (You Need to Do)

### 1. URL Configuration

Go to: https://supabase.com/dashboard/project/dnasghxxqwibwqnljvxr/auth/url-configuration

- [ ] Set **Site URL** to: `com.example.flowfit://auth-callback`
- [ ] Add to **Redirect URLs**:
  - [ ] `com.example.flowfit://auth-callback`
  - [ ] `com.example.flowfit.dev://auth-callback`
  - [ ] `http://localhost:3000/**`

### 2. Email Templates

Go to: https://supabase.com/dashboard/project/dnasghxxqwibwqnljvxr/auth/templates

- [ ] Verify "Confirm signup" template uses `{{ .ConfirmationURL }}`
- [ ] Customize email subject and body if desired
- [ ] Save changes

### 3. Auth Settings

Go to: https://supabase.com/dashboard/project/dnasghxxqwibwqnljvxr/auth/providers

- [ ] Verify **Email Provider** is enabled
- [ ] Verify **Confirm Email** is ON (or OFF for testing)
- [ ] Check **Email Confirmation Expiry** (default: 24 hours)

## 🧪 Testing (You Need to Do)

### Quick Test (2 minutes)

```bash
# 1. Rebuild the app
flutter run -d <device-id>

# 2. Test deep link opens app
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.example.flowfit://auth-callback" \
  com.example.flowfit
```

**Expected**: App should open

### Full Email Test (5 minutes)

1. [ ] Sign up with a real email address
2. [ ] Check email inbox (and spam folder)
3. [ ] Click verification link on device
4. [ ] App should open automatically
5. [ ] User should be verified and redirected to survey

### Monitor Logs

```bash
# Watch for auth events
adb logcat | grep -i "deep link\|auth\|flutter"
```

**Look for**:
- "Handling deep link: ..."
- "Auth state changed: signedIn"
- "User signed in via deep link: ..."

## 🐛 Troubleshooting

### Issue: App doesn't open from email link

**Check**:
- [ ] Redirect URLs are configured in Supabase Dashboard
- [ ] Site URL is set correctly
- [ ] AndroidManifest.xml has intent filter (already done)

**Test**:
```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.example.flowfit://auth-callback" \
  com.example.flowfit
```

### Issue: Email not sending

**Check**:
- [ ] Email provider is enabled in Supabase
- [ ] Email address is valid
- [ ] Check spam folder
- [ ] Check Supabase logs for errors

**Supabase Logs**: https://supabase.com/dashboard/project/dnasghxxqwibwqnljvxr/logs/explorer

### Issue: Token expired

**Solution**: 
- Links expire after 24 hours
- Use "Resend Email" button in app
- Or sign up again with same email

### Issue: App crashes on deep link

**Check logs**:
```bash
adb logcat | grep -i "exception\|error"
```

**Common causes**:
- Navigation context not available
- Null pointer in deep link handler
- Missing auth state listener

## 📱 Device Testing

Test on:
- [ ] Android 8.0+ (minimum supported)
- [ ] Different manufacturers (Samsung, Google, etc.)
- [ ] Real device (not just emulator)
- [ ] With app in foreground
- [ ] With app in background
- [ ] With app closed

## 🚀 Before Production

- [ ] Update package name from `com.example.flowfit` to production
- [ ] Update deep link schemes to match production package
- [ ] Remove development deep link schemes
- [ ] Update Supabase redirect URLs for production
- [ ] Test with multiple real email addresses
- [ ] Set up custom SMTP for better deliverability
- [ ] Enable email confirmation in Supabase
- [ ] Test rate limiting
- [ ] Monitor auth logs for issues

## 📚 Documentation Reference

- [Setup Guide](./MOBILE_DEEP_LINKING_SETUP.md) - Complete setup instructions
- [Dashboard Config](./SUPABASE_DASHBOARD_CONFIG.md) - Supabase configuration
- [Testing Guide](./DEEP_LINK_TESTING.md) - Testing with ADB commands
- [Summary](./EMAIL_VERIFICATION_SETUP_SUMMARY.md) - Quick reference

## 🆘 Need Help?

1. Check Supabase logs: https://supabase.com/dashboard/project/dnasghxxqwibwqnljvxr/logs/explorer
2. Check app logs: `adb logcat | grep -i "flutter\|auth"`
3. Review documentation in `docs/` folder
4. Check Supabase Discord or GitHub issues

## ✨ Success Criteria

You'll know it's working when:

1. ✅ Deep link test opens the app
2. ✅ Sign up sends verification email
3. ✅ Email link opens app automatically
4. ✅ User is verified and redirected to survey
5. ✅ No errors in logs

---

**Current Status**: Code changes complete ✅  
**Next Step**: Configure Supabase Dashboard (see section above)
