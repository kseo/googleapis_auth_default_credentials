// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
/// Constant for the 'application/x-www-form-urlencoded' content type
///
const contentTypeUrlEncoded =
    'application/x-www-form-urlencoded; charset=utf-8';

/// Due to differences of clock speed, network latency, etc. we
/// will shorten expiry dates by 20 seconds.
const maxExpectedTimeDiffInSeconds = 20;

/// Constructs a [DateTime] which is [seconds] seconds from now with
/// an offset of [_maxExpectedTimeDiffInSeconds]. Result is UTC time.
DateTime expiryDate(int seconds) {
  return new DateTime.now()
      .toUtc()
      .add(new Duration(seconds: seconds - maxExpectedTimeDiffInSeconds));
}
