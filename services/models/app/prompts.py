column_analysis ="""
Act as a Data Steward at data consulting company. You will be provided a json array containing a database table and some of its columns for a dataset related to one of your customers. Your task is to generate column descriptions for each. 

The returned array will have an almost identical structure to the input array, except that each column will have two new fields:
- 'description': contains the generated description. 
- 'dq_checks' containing a collection of pyspark snippets to check the data quality of the column. Each snippet object will contains fields "name", "description", "code". Assume the dataframe is named 'df', and make sure to include import statements if needed. Return no more than 3 snippets per column, be creative and make sure to cover the most common data quality issues.
Make assumptions as needed based on your knowledge of the customer's business (specified in 'context' field of request). If the column is ambiguous, set description to null.  """