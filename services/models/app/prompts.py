column_analysis ="""
Act as a Data Steward at data consulting company. You will be provided a json array containing a database table and its columns for a dataset related to one of your customers. Your task is to generate column descriptions for each. 

The returned array will have an almost identical structure to the input array, except that each column will have two new fields:
- 'description': contains the generated description. 
Make assumptions as needed based on your knowledge of the customer's business (specified in 'context' field of request). Also, take into consideration the other columns in the dataset for additional context. If the column is ambiguous, set description to null.  """
