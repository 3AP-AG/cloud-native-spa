# Cloud Native SPA

## The problem

Currently, our go-to approach to deploy SPA into a cloud-native environment is to use the nginx 
regex filter magic with envsubst. This allows us to have one deployable artifact but be able 
to change configurations per environment.

While this approach works very well I still feel thats it's a hacky solution.

Are there alternative solutions available?

https://stackoverflow.com/c/3ap/questions/24

## Solutioin

Using React as our strategic technology for SPA, and create-react-app as option for scaffolding 
React SPA, we are all using their approach for [environment variables](https://create-react-app.dev/docs/adding-custom-environment-variables). 

The main problem here is that they only work at compile time. 

Another problem is that optimizer can do some pre-calculations with current environment variables 
which can lead to some strange bugs. For example, if you type something like this in your code
```ts
const foo = process.env.REACT_APP_FOO === "true";
```
in compile time you don't have your environment variables set yet. Then, optimizer will change
`prcess.env.REACT_APP_FOO` with empty string. Then it will try to go further, it sees that `"" === "true"`
is `false`. So, at the end, all you get in your compiled js file is `const foo = false;`, which means
that we loose placeholder for env substitution. This kind of "bugs" are really hard to follow and debug. 

In addition to the above, our current approach is bad for browser cacheing. If browser caches js file, 
which was filtered on nginx level, there is no way you can apply new environment variables 
without creating new artifact with different filename.

In order to solve this, we need something which will apply env vars at runtime and not in build time. 
Approach in this repo would be to generate file called env.js when container starts and 
contains all env vars. That generated file should be stored in public directory and assign 
all env vars to window object. Content for the generated `env.js` file will be something like this:

```js
window.env = {
  // Here we should list all available env vars which app uses 
  // with values from env for that container
  REACT_APP_API_KEY: "api-key",
  REACT_APP_API_URL: "http://localhost:8080",
}
```

Script for creating this `env.js` file is [here](scripts/generate-env-file.sh). 
We also want to explicitly tell the script which env vars should be there. In order to do that, 
we use file [.env.template](.env.template). 
Note that values in `.env.template` are set to some random value (`xxx`), 
because we don't care about them, we care only for keys. 

So, to summarize, script is running through `.env.template`, for each row checks if key starts with 
`REACT_APP_`, and, if condition is satisfied, adds new row in generated file with properly set env var.

In order to apply new env vars, this script should run whenever container starts. 
We can do that defining new script for entrypoint in [Dockerfile](Dockerfile) like this 
```
ENTRYPOINT [ "sh", "/nginx-entrypoint.sh" ]
```
This `nginx-entrypoint.sh` will start our script for generating `env.js` file, and after that it 
will start nginx server.

In [nginx.conf](nginx.conf) we see that every request is cached (in the browser) except for `env.js`. 

The only thing left is consumption of our generated `env.js` file. First thing is that we 
include that file in [index.html](public/index.html) like this: 

```html
<% if (process.env.NODE_ENV === 'production') { %>
    <script src="%PUBLIC_URL%/env.js"></script>
<% } %>
```
We want to include `env.js` file only in production. For development purposes we can read values 
from `process.env`. We don't want to generate new file every time we start dev server.

Next, we can create file which exports env object like [this](src/env.ts):
```ts
type EnvKey =
  | "REACT_APP_API_KEY"
  | "REACT_APP_API_URL";

export const env =
  process.env.NODE_ENV === "development"
    ? Object.keys(process.env).reduce((acc, curr) => {
        if (curr.startsWith("REACT_APP_")) {
          acc[curr as EnvKey] = process.env[curr] as string;
        }
        return acc;
      }, {} as Record<EnvKey, string>)
    : ((window as any).env as Record<EnvKey, string>);
```
and use it like this in our application
```tsx
import { env } from "./env";

console.log(env.REACT_APP_API_KEY);
```

## Conclusion
Proposed solution here solves two main problems which exists in regex filter magic with envsubst.

1. Browser caching: Here we can use headers to enable browser cache for every js or css file 
   without thinking about the magic with envsubst. nginx doesn't change any of our file
2. Strange bugs with optimizers' pre-calculation. 

You can play around with `docker-compose` on this repo to see what's happening. 
Stop container, change environment, run container

Cheers! 🍻
