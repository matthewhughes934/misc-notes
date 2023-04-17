# Computing padding

This can be computed with `unsafe.SizeOf`, for example:

``` go
package main

import (
	"fmt"
	"unsafe"
)

type lotsOfPadding struct {
	flag    bool
	counter int64
	val     float32
}

type lessPadding struct {
	counter int64
	val     float32
	flag    bool
}

func main() {
	fmt.Println(unsafe.Sizeof(lotsOfPadding{}))
	fmt.Println(unsafe.Sizeof(lessPadding{}))
}
```
