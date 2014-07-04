#if Rails.env.productin?
#  Braintree::Configuration.environment = :production
#  Braintree::Configuration.merchant_id = 'zbmks22nbf8nfm78'
#  Braintree::Configuration.public_key = 'w5994pjmp9z6xqws'
#  Braintree::Configuration.private_key = 'e62187bb9bf41e08c13ef49937c5823a'
#else
  Braintree::Configuration.environment = :sandbox
  Braintree::Configuration.merchant_id = 'vfhpwqw9g896qnzh'
  Braintree::Configuration.public_key = 'p8s4g5cpczwqj3gp'
  Braintree::Configuration.private_key = '97f4b0a67bf1974bea764beccd95f8f4'
#end
