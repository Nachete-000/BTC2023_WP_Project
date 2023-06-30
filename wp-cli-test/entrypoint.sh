#!/bin/bash

# Function to create posts
function createpost	{
	# Create Post
		echo -e "\033[0;34m# ⚙️   Creating post $N of $TIMES..."

	# Generate ramdon post category, split line from .env into array
		echo -e "\033[0;36m# ⚙️⚙️     Creating random category for post"
		RANDOMCONTENT=${CONTENTARRAY[$RANDOM % ${#CONTENTARRAY[*]}]}

	# Generate random tag, split variable from .env into array
		echo -e "\033[0;36m# ⚙️⚙️     Creating random tag for post..."
		RANDOMTAG=${TAGSARRAY[$RANDOM % ${#TAGSARRAY[*]}]}

	# Get text from loripsum api from 1 to 30 number
		echo -e "\033[0;36m# ⚙️⚙️     Creating random text for post..."
		RANDOMTXT=$(shuf -i 1-30 -n 1)
		TEXT=$(curl --silent https://loripsum.net/api/$RANDOMTXT)
		TIMESTAMP=$(date +%Y%m%d-%H%M%S)
		wp post create --post_type=post --post_status=publish --post_title="A new deploy in Branch: ${BRANCH_NAME} with build number: ${BUILD_ID} post: ${TIMESTAMP}" --color --post_content="${TEXT}"

	# Get last Post created in WP and add to variable value
		echo -e "\033[0;36m# ⚙️⚙️     Get last post..."
		LASTPOST=$(wp post list --field=ID --posts_per_page=1)

	# Generate random number from 1 to x to select image to upload (The script count the number of files and select a random from n to load to wordpress, then add a random image to post)
	# Count files in directory to select one ramdomly.
		echo -e "\033[0;36m# ⚙️⚙️     Select random image..."
		COUNTFILES=$(ls /tmp/img/*.jpg | wc -l)
		IMGFILE=$(shuf -i 1-${COUNTFILES} -n 1)
		echo -e "\033[0;34m# ⚙️   Attach image wp$IMGFILE.jpg to post..."

	# Update last post with random image from file scratch and enable as featured image
		wp media import /tmp/img/wp$IMGFILE.jpg --post_id=$LASTPOST --title="${BRANCH_NAME} ${BUILD_ID} ${TIMESTAMP}" --featured_image

	# Update last post with TAG and CONTENT
		echo -e "\033[0;36m# ⚙️⚙️     Updating tag ${RANDOMTAG} to post..."
		wp post update ${LASTPOST} --tags_input=${RANDOMTAG}

		echo -e "\033[0;36m# ⚙️⚙️     Updating category ${RANDOMCONTENT} to post..."
		wp post update ${LASTPOST} --post_category=${RANDOMCONTENT}
}

# Function to create user comments
function createcomment {
		# Generate a random username
		POSTUSER=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c $(shuf -i 1-20 -n 1) ;)
		# Generate comment in last post with fortune
		COMMENT=$(fortune)
		wp comment create --comment_post_ID=${LASTPOST} --comment_content="${COMMENT}" --comment_author=${POSTUSER}
}

# Start Script
#
# Init counter for comments
# #
	COUNTERCOMMENT=0

# Get previous status
# All total posts
# #
	SITETOTALPOSTS=$(wp post list --format=count)
	# Number all comments
	SITETOTALCOMMENTS=$(wp comment list --format=count)
	# Number all categories
	SITETOTALCATEGORIES=$(wp term list category --format=count)
	# Number all tas
	SITETOTALTAGS=$(wp term list post_tag --format=count)

# Only run for standalone & dev & stg, not required in prod
if [ "${BRANCH_NAME}" = "standalone" ] || [ "${BRANCH_NAME}" = "dev" ] || [ "${BRANCH_NAME}" = "stg" ]; then

	# Generate ramdon post content with random variable, split line from .env into array
		CONTENTARRAY=(`echo $CONTENT | tr ',' ' '`)
		# Create Category list if not exist
		echo -e "\033[0;35m# ⚙️⚙️⚙️   Creating category content in db..."
		
		for CATEGORY in ${CONTENTARRAY[@]};	do
			# Check if category exists, if exsist skip to next, if no t exists create
			CATEGORYEXIST=$(wp term list category --by=term_id --field=name |grep -w ${CATEGORY})
			if [ "${CATEGORYEXIST}" = "$CATEGORY" ]; then
				echo -e "\033[0;35m# ⚙️⚙️⚙️   Category $CATEGORY already exists in db..."
			else
				echo -e "\033[0;35m# ⚙️⚙️⚙️   Creating $CATEGORY in db..."
				wp term create category ${CATEGORY} --description="${CATEGORY}" >/dev/null
			fi
		done

	# Get tags from array
		TAGSARRAY=(`echo $TAGS | tr ',' ' '`)

	# Create a loop to generate some posts
		# Create posts between 1 to number defined in .env variable, condition if random enabled or fixed number
		case ${POSTRANDOM} in
			[Yy]*) TIMES=$(shuf -i 1-${NUMBERPOST} -n 1) ;;
				*) TIMES=${NUMBERPOST} ;;
		esac

		# Repeat Post creation
		for((N=0; N<TIMES; N++)); do
			# Call to function generate post
			createpost

			# Create comments between 1 to number defined in variable, condition if random enabled or fixed number
			if [ "${POSTRANDOM}" = 'N' ]; then
				RNDCOMMENT=${NUMBERCOMMENTS}
			else
				RNDCOMMENT=$(shuf -i 1-${NUMBERCOMMENTS} -n 1)
			fi

			# Create comment
			echo -e "\033[0;33m# ⚙️⚙️     Creating $RNDCOMMENT comments..."
			for((I=0; I<RNDCOMMENT; I++)); do {

				# Call to function create comment
				createcomment

				# Wait between time set from var to create a new comment
				COMMENTWAIT=$(shuf -i ${MINWAITTIMECOMMENT}-${MAXWAITTIMECOMMENT} -n 1)
				echo -e "\033[0;33m# ⚙️⚙️     Wait $COMMENTWAIT seconds for new comment..."
				sleep $COMMENTWAIT

				# Increase counter to calc sequence repeat
				let COUNTERCOMMENT++
			}
			done

			# Interval wait to generate post
			# Set interval in seconds between 30 to time from env var .
			TIMEWAIT=$(shuf -i ${MINWAITTIMEPOST}-${MAXWAITTIMEPOST} -n 1)
			echo -e "\033[0;36m# ⚙️⚙️     Wait $TIMEWAIT seconds for new post"
			sleep $TIMEWAIT
		done

		# Count all post
		TOTALPOSTS=$(wp post list --format=count)
		# Count all comments
		TOTALCOMMENTS=$(wp comment list --format=count)
		# Count all categories
		TOTALCATEGORIES=$(wp term list category --format=count)
		# Count all tags
		TOTALTAGS=$(wp term list post_tag --format=count)
		
		# Present results
		# Change env variable WPCLI to 1 to enable
			echo ""
			echo -e "\033[0;92m##################################################"
			echo -e "\033[0;92m### Installed Plugin:                          ###"
			echo -e "\033[0;92m##################################################"
			# WP list all installed plugins
			wp plugin list

			echo -e "\033[0;92m##################################################"
			echo -e "\033[0;92m### Site:                                        #"

			echo -e "\033[0;92m    - Branch name   : "${BRANCH_NAME}
			echo -e "\033[0;92m    - Build id      : "${BUILD_ID}
			echo -e "\033[0;92m    - New Posts     : "${TIMES}
			
			# Dispaly information if random post is enabled
			case ${POSTRANDOM} in
				[Yy]*) 
					echo -e "\033[0;92m    - Random post   : "${POSTRANDOM}
					echo -e "\033[0;92m    - Random post   : "${COUNTER} ;;
				*)  
					echo -e "\033[0;92m    - Random post   : Disabled" ;;
			esac
			
			# Previous content in WP
			echo -e "\033[0;92m    - Prev. posts   : "${SITETOTALPOSTS}
			echo -e "\033[0;92m    - Prev. comments: "${SITETOTALCOMMENTS}
			echo -e "\033[0;92m    - Prev. categ   : "${SITETOTALCATEGORIES}
			echo -e "\033[0;92m    - Prev. tags    : "${SITETOTALTAGS}
			# Total content in WP
			echo -e "\033[0;92m    - Total posts   : "${TOTALPOSTS}
			echo -e "\033[0;92m    - Total comments: "${TOTALCOMMENTS}
			echo -e "\033[0;92m    - Total categ.  : "${TOTALCATEGORIES}
			echo -e "\033[0;92m    - Total tags    : "${TOTALTAGS}
			# Added content in WP
			echo -e "\033[0;92m    - New posts     : "${TIMES}
			echo -e "\033[0;92m    - New comments  : "${COUNTERCOMMENT}
			echo -e "\033[0;92m##################################################"
			echo -e "\033[0;92m##################################################"
			echo -e "\033[0;92m Status"
			
			# Count Operations to check result
			# Calc Posts created
			RESULTPOSTS=$((TIMES + SITETOTALPOSTS))
			if [ ${TOTALPOSTS} == ${RESULTPOSTS} ]; then
				echo -e "\033[0;32m Ok: Posts"
			else
				echo -e "\033[0;31m Error: Posts"
			fi

			# Calc Comments created
			RESULTCOMMENTS=$((COUNTERCOMMENT + SITETOTALCOMMENTS))
			if [ ${TOTALCOMMENTS} == ${RESULTCOMMENTS} ]; then
				echo -e "\033[0;32m Ok: Comments"
			else
				echo -e "\033[0;31m Error: Comments"
			fi
			
			# Check if all categories in variable was created
			# Count all array and compare with categories
			EXPR=$CONTENTARRAY[@]
			CONTENTARRAYCOPY=( "${!EXPR}" )
			COUNTCATEGORIES=${#CONTENTARRAYCOPY}
			if [ ${TOTALCATEGORIES} != ${COUNTCATEGORIES} ]; then
				echo -e "\033[0;32m Ok: Categories"
			else
				echo -e "\033[0;31m Error: Categories"
			fi
			
			# Check if at least was created one tag
			if [ ${TOTALTAGS} -gt 0 ]; then
				echo -e "\033[0;32m Ok: Tags"
			else
				echo -e "\033[0;31m Error: Tags"
			fi

			if [ ${TOTALPOSTS} == ${RESULTPOSTS} ] && [ ${TOTALCOMMENTS} == ${RESULTCOMMENTS} ] && [ ${TOTALCATEGORIES} != ${COUNTCATEGORIES} ] && [ ${TOTALTAGS} -gt 0 ]; then
				echo -e "\033[0;92m Output Ok"
			else 
				echo -e "\033[0;31m Output Error"
				exit 1
			fi
			
			if [ ${BRANCH_NAME} = "standalone" ]; then
				echo
						# This command permit manage wp-cli console without exit at end of the script connecting to running image for test purpouses
			# tail -f /dev/null
			fi
fi
