# Unity PCF (Poisson Sampling)

## Examples

Shadow resolution is set to 4096 in all examples.

Hard shadows (built-in)

![Hard Shadows](Documentation/hard_shadows.jpg)

Soft shadows (built-in)

![Soft Shadows](Documentation/soft_shadows.jpg)

Poisson Sampling
- Spread: 1200
- Samples 16

![Poisson (Default, 16)](Documentation/poisson_default_16.jpg)

Poisson Sampling
- Spread: 1500
- Samples 4

![Poisson (Default, 4)](Documentation/poisson_default_4.jpg)

Poisson Sampling (Stratified)
- Spread: 2000
- Samples: 16

![Poisson (Stratified)](Documentation/poisson_stratified.jpg)

Poisson Sampling (Rotated)
- Spread: 1000
- Samples: 16

![Poisson (Rotated)](Documentation/poisson_rotated.jpg)

## References

- http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-16-shadow-mapping/#aliasing
- https://dev.theomader.com/shadow-quality-2/