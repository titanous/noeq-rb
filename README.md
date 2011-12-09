# noeq-rb

noeq-rb is a [noeqd](https://github.com/bmizerany/noeqd) GUID client in Ruby.

[Annotated source code is available](http://titanous.com/noeq-rb/).

## Installation

```
gem install noeq
```

## Usage

### One-time GUID from localhost

```ruby
require 'noeq'
Noeq.generate(2) #=> [142692304753262592, 142692304753262593]
```

### Regular usage

```ruby
require 'noeq'

noeq = Noeq.new('idserver.local')
noeq.generate #=> 142692638036852736
noeq.generate(5) #=> [142692782450933760, 142692782450933761, 142692782450933762, 142692782450933763, 142692782450933764]
```

### Async usage

```ruby
require 'noeq'

noeq = Noeq.new('localhost', 4444, :async => true)
noeq.request_id
# do some things
noeq.fetch_id #=> 142692638036852736
```
