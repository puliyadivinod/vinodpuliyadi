--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Monad (forM_, forM, liftM)
import           Data.Monoid (mappend, mconcat)
import           Data.Maybe
import qualified Data.Map as M
import           Hakyll
import           Data.List              (isSuffixOf, isPrefixOf, isInfixOf,
                                         intercalate, sort)
import           System.FilePath.Posix  (takeBaseName, takeDirectory,
                                         (</>), takeFileName)
import           Text.Blaze.Html                 (toHtml, toValue, (!))
import           Text.Blaze.Html.Renderer.String (renderHtml)
import qualified Text.Blaze.Html5                as H
import qualified Text.Blaze.Html5.Attributes     as A

--------------------------------------------------------------------------------
host :: String
host = "https://vinodpuliyadi.pro"

siteName :: String
siteName = "The Whimsy Coder"

sourceRepository :: String
sourceRepository = "https://github.com/puliyadivinod/vinodpuliyadi"

siteAuthor :: String
siteAuthor = "Vinodkumar Puliyadi"

siteEmail :: String
siteEmail = "puliyadivinod@gmail.com"

siteDescription :: String
siteDescription = "Passionate of opensource software's and hardware, always keen to learn and share; looking for good projects and tasty food."

siteDisqusSiteShortname :: String
siteDisqusSiteShortname = "vinodpuliyadi"

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle = siteName
    , feedDescription = siteDescription
    , feedAuthorName = siteAuthor
    , feedAuthorEmail = siteEmail
    , feedRoot = host
    }

copyFiles :: [Pattern]
copyFiles = [ "fonts/*"
            , "css/*"
            , "images/*"
            , "errors/404.html"
            , "CNAME"
            , "robots.txt"
            , "favicon.ico"
            , ".htaccess"
            ]

config :: Configuration
config = defaultConfiguration
    { deployCommand = "./scripts/deploy-cmd.sh"
    , ignoreFile = ignoreFile'
    }

    where
        ignoreFile' path
            | "~" `isPrefixOf` fileName = True
            | ".#" `isPrefixOf` fileName = True
            | "~" `isSuffixOf` fileName = True
            | ".swp" `isSuffixOf` fileName = True
            | ".git" `isInfixOf` path = True
            | "_cache" `isInfixOf` path = True
            | otherwise = False
            where
                fileName = takeFileName path

main :: IO ()
main = hakyllWith config site

site :: Rules ()
site = do
  forM_ copyFiles $ \pattern->
      match pattern $ do
         route   idRoute
         compile copyFileCompiler

  match "css/*" $ do
         route   idRoute
         compile compressCssCompiler

  tags <- buildTags "posts/*/*" (fromCapture "tags/*.html")
  years <- buildYears "posts/*/*"
  let draftCtx = mconcat [ postSlugField "slug"
                         , postYearField "year"
                         , pageCtx ]
  let postCtx = mconcat [ tagsField "tags" tags
                        , teaserField "teaser" "content"
                        , draftCtx]

  match "drafts/*" (postRules $ draftCtx)
  match "posts/*/*" (postRules $ postCtx)

  match "pages/*" $ do
         route   $ cleanRoute `composeRoutes` (gsubRoute "pages/" (const ""))
         compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/page.html" pageCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" pageCtx
            >>= relativizeUrls
            >>= cleanIndexUrls

  create ["blog.html"] $ do
         route   $ cleanRoute `composeRoutes` (gsubRoute "pages/" (const ""))
         compile $ do
           posts <- fmap (take 7) . recentFirst =<< loadAll "posts/*/*"
           let indexCtx = mconcat
                          [ listField "posts" postCtx (return posts)
                          , constField "title" "Recent Posts"
                          , field "tags" (\_ -> renderTagCloud 100 300 tags)
                          , field "years" (\_ -> renderYears years)
                          , myCtx
                          ]

           makeItem ""
            >>= loadAndApplyTemplate "templates/posts.html" indexCtx
            >>= loadAndApplyTemplate "templates/default.html" indexCtx
            >>= relativizeUrls
            >>= cleanIndexUrls


  create ["index.html"] $ do
         route   idRoute
         compile $ do
           let indexCtx = mconcat
                          [ constField "title" siteAuthor
                          , myCtx
                          ]

           makeItem ""
            >>= loadAndApplyTemplate "templates/index.html" indexCtx
            >>= loadAndApplyTemplate "templates/home.html" indexCtx
            >>= relativizeUrls
            >>= cleanIndexUrls

  forM_ years $ \(year, _)->
      create [yearId year] $ do
         route   idRoute
         compile $ do
           posts <- recentFirst =<< loadAll (fromGlob $ "posts/" ++ year ++"/*")
           let postsCtx = mconcat
                          [ listField "posts" postCtx (return posts)
                          , constField "title" ("Posts published in " ++ year)
                          , field "years" (\_ -> renderYears years)
                          , myCtx
                          ]
           makeItem ""
            >>= loadAndApplyTemplate "templates/posts.html" postsCtx
            >>= loadAndApplyTemplate "templates/default.html" postsCtx
            >>= relativizeUrls
            >>= cleanIndexUrls

  tagsRules tags $ \tag pattern -> do
         -- Copied from posts, need to refactor
         route cleanRoute
         compile $ do
           posts <- recentFirst =<< loadAll pattern
           let postsCtx = mconcat
                          [ listField "posts" postCtx (return posts)
                          , constField "title" ("Posts tagged " ++ tag)
                          , field "years" (\_ -> renderYears years)
                          , myCtx
                          ]

           makeItem ""
            >>= loadAndApplyTemplate "templates/posts.html" postsCtx
            >>= loadAndApplyTemplate "templates/default.html" postsCtx
            >>= relativizeUrls
            >>= cleanIndexUrls

  create ["sitemap.xml"] $ do
         route   idRoute
         compile $ do
           posts <- recentFirst =<< loadAll "posts/*/*"
           pages <- loadAll "pages/*"

           let allPosts = (return (pages ++ posts))
           let sitemapCtx = mconcat
                            [ listField "entries" pageCtx allPosts
                            , constField "host" host
                            , myCtx
                            ]

           makeItem ""
            >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx
            >>= cleanIndexHtmls

  create ["feed.xml"] $ do
         route   idRoute
         compile $ do
           let feedCtx = pageCtx `mappend` bodyField "description"
           posts <- fmap (take 10) . recentFirst =<<
                   loadAllSnapshots "posts/*/*" "content"
           renderAtom myFeedConfiguration feedCtx posts
             >>= cleanIndexHtmls

  match "_includes/*" $ compile templateCompiler
  match "templates/*" $ compile templateCompiler

--------------------------------------------------------------------------------

myCtx :: Context String
myCtx = mconcat
  [ constField "superTitle" siteName
  , constField "siteAuthor" siteAuthor
  , constField "siteEmail" siteEmail
  , constField "siteDescription" siteDescription
  , constField "source" sourceRepository
  , constField "host" host
  , constField "disqus_site_shortname" siteDisqusSiteShortname
  , defaultContext
  ]

pageCtx :: Context String
pageCtx = mconcat
    [ modificationTimeField "mtime" "%U"
    , modificationTimeField "lastmod" "%Y-%m-%d"
    , dateField "updated" "%Y-%m-%dT%H:%M:%SZ"
    , constField "host" host
    , constField "source" sourceRepository
    , dateField "date" "%B %e, %Y"
    , myCtx
    ]

postRules :: Context String -> Rules ()
postRules ctx = do
    route   $ postCleanRoute
    compile $ pandocCompiler
       >>= loadAndApplyTemplate "templates/post-content.html" ctx
       >>= saveSnapshot "content"
       >>= loadAndApplyTemplate "templates/post.html" ctx
       >>= loadAndApplyTemplate "templates/default.html" ctx
       >>= relativizeUrls
           >>= cleanIndexUrls

-- custom routes
--------------------------------------------------------------------------------
postCleanRoute :: Routes
postCleanRoute = cleanRoute
 `composeRoutes` (gsubRoute "(posts/[0-9]{4}/|drafts/)" (const ""))

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeDirectory p </> takeBaseName p </> "index.html"
                            where p = toFilePath ident

cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = return . fmap (withUrls cleanIndex)

cleanIndexHtmls :: Item String -> Compiler (Item String)
cleanIndexHtmls = return . fmap (replaceAll pattern replacement)
    where
      pattern = "/index.html"
      replacement = const "/"

cleanIndex :: String -> String
cleanIndex url
    | idx `isSuffixOf` url = take (length url - length idx) url
    | otherwise            = url
  where idx = "index.html"

-- utils
--------------------------------------------------------------------------------

type Year = String

buildYears :: MonadMetadata m => Pattern -> m [(Year, Int)]
buildYears pattern = do
    ids <- getMatches pattern
    return . frequency . (map getYear) $ ids
  where
    frequency xs =  M.toList (M.fromListWith (+) [(x, 1) | x <- xs])

postSlugField :: String -> Context a
postSlugField key = field key $ return . baseName
  where baseName = takeBaseName . toFilePath . itemIdentifier

postYearField :: String -> Context a
postYearField key = field key $ return . getYear . itemIdentifier

getYear :: Identifier -> Year
getYear = takeBaseName . takeDirectory . toFilePath

yearPath :: Year -> FilePath
yearPath year = "archive/" ++ year ++ "/index.html"

yearId :: Year -> Identifier
yearId = fromFilePath . yearPath

renderYears :: [(Year, Int)] -> Compiler String
renderYears years = do
  years' <- forM (reverse . sort $ years) $ \(year, count) -> do
      route' <- getRoute $ yearId year
      return (year, route', count)
  return . intercalate ", " $ map makeLink years'

  where
    makeLink (year, route', count) =
      (renderHtml (H.a ! A.href (yearUrl year) $ toHtml year)) ++
      " (" ++ show count ++ ")"
    yearUrl = toValue . toUrl . yearPath