通过重载父视图的- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event方法，遍历它的所有子视图，看是否符合。代码如下:

```
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        for (UIView *v in self.subviews) {
            CGPoint p = [v convertPoint:point fromView:self];
            if (CGRectContainsPoint(v.bounds, p)) {
                view = v;
            }
        }
    }
    return view;
}
```